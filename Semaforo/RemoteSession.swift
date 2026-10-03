import Combine
import MultipeerConnectivity
import UIKit

/// Messages exchanged between a controller and the traffic light it drives.
enum RemoteMessage: Codable {
    /// Controller -> light: advance to the next enabled color, like a tap.
    case next
    /// Controller -> light: jump straight to a color.
    case set(Signal)
    /// Light -> controller: current color, which colors are enabled, and
    /// whether the timer is running (remote commands are ignored then).
    case state(current: Signal, enabled: [Signal], timerEnabled: Bool)
}

/// Pairs nearby iPhones over Wi-Fi/Bluetooth using a 4-digit code.
///
/// The light side advertises and only accepts invitations carrying its code.
/// The controller side browses and invites every light it finds with the typed
/// code, so only the matching one accepts.
final class RemoteSession: NSObject, ObservableObject {
    enum Role { case idle, light, controller }

    enum ControllerStatus: Equatable {
        case idle, searching, connected, notFound, disconnected
    }

    private static let serviceType = "semaforo"
    private static let searchTimeout: TimeInterval = 10

    @Published private(set) var role: Role = .idle
    @Published private(set) var code: String = ""
    @Published private(set) var connectedControllers = 0
    @Published private(set) var controllerStatus: ControllerStatus = .idle
    @Published private(set) var remoteSignal: Signal?
    @Published private(set) var remoteEnabled: [Signal] = Signal.displayOrder
    @Published private(set) var remoteTimerEnabled = false

    /// Commands received while acting as a light.
    let commands = PassthroughSubject<RemoteMessage, Never>()

    private let peerID = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var searchTimer: Timer?
    private var lastState: RemoteMessage?

    // MARK: Light

    func startLight() {
        guard role != .light else { return }
        stop()
        code = String(format: "%04d", Int.random(in: 0...9999))
        session = makeSession()
        let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: Self.serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser
        role = .light
    }

    /// Broadcasts the light's current state to every connected controller.
    func publish(current: Signal, enabled: [Signal], timerEnabled: Bool) {
        let message = RemoteMessage.state(current: current, enabled: enabled, timerEnabled: timerEnabled)
        lastState = message
        send(message)
    }

    // MARK: Controller

    func connect(code: String) {
        stop()
        self.code = code
        session = makeSession()
        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
        role = .controller
        controllerStatus = .searching
        searchTimer = Timer.scheduledTimer(withTimeInterval: Self.searchTimeout, repeats: false) { [weak self] _ in
            guard let self, self.controllerStatus == .searching else { return }
            self.stop()
            self.controllerStatus = .notFound
        }
    }

    func sendNext() { send(.next) }

    func send(signal: Signal) { send(.set(signal)) }

    // MARK: Shared

    func stop() {
        searchTimer?.invalidate()
        searchTimer = nil
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        session?.disconnect()
        session = nil
        role = .idle
        code = ""
        connectedControllers = 0
        controllerStatus = .idle
        remoteSignal = nil
        remoteTimerEnabled = false
        lastState = nil
    }

    private func makeSession() -> MCSession {
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }

    private func send(_ message: RemoteMessage, to peers: [MCPeerID]? = nil) {
        guard let session, let data = try? JSONEncoder().encode(message) else { return }
        let targets = peers ?? session.connectedPeers
        guard !targets.isEmpty else { return }
        try? session.send(data, toPeers: targets, with: .reliable)
    }

    private func handle(_ message: RemoteMessage) {
        switch (role, message) {
        case (.light, .next), (.light, .set):
            commands.send(message)
        case let (.controller, .state(current, enabled, timerEnabled)):
            remoteSignal = current
            remoteEnabled = enabled
            remoteTimerEnabled = timerEnabled
        default:
            break
        }
    }
}

// MARK: - MCSessionDelegate

extension RemoteSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            guard session === self.session else { return }
            switch self.role {
            case .light:
                self.connectedControllers = session.connectedPeers.count
                if state == .connected, let lastState = self.lastState {
                    self.send(lastState, to: [peerID])
                }
            case .controller:
                switch state {
                case .connected:
                    self.searchTimer?.invalidate()
                    self.browser?.stopBrowsingForPeers()
                    self.controllerStatus = .connected
                case .notConnected where self.controllerStatus == .connected:
                    self.controllerStatus = .disconnected
                    self.remoteSignal = nil
                default:
                    break
                }
            case .idle:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(RemoteMessage.self, from: data) else { return }
        DispatchQueue.main.async {
            guard session === self.session else { return }
            self.handle(message)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension RemoteSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            let offered = context.flatMap { String(data: $0, encoding: .utf8) }
            if self.role == .light, let session = self.session, offered == self.code {
                invitationHandler(true, session)
            } else {
                invitationHandler(false, nil)
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension RemoteSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            guard browser === self.browser, let session = self.session else { return }
            browser.invitePeer(peerID, to: session, withContext: Data(self.code.utf8), timeout: Self.searchTimeout)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
