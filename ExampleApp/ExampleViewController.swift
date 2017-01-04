import UIKit
@testable import TradeItIosTicketSDK2

struct Section {
    let label: String
    let actions: [Action]
}

struct Action {
    let label: String
}

let sections = [
    Section(label: "TradeIt Flows", actions: [
        Action(label: "launchPortfolio"),
        Action(label: "launchPortfolioForLinkedBrokerAccount"),
        Action(label: "launchPortfolioForAccountNumber"),
        Action(label: "launchTrading"),
        Action(label: "launchTradingWithSymbol"),
        Action(label: "launchAccountManagement"),
        Action(label: "launchOAuthFlow"),
        Action(label: "launchOAuthRelinkFlow"),
        Action(label: "launchBrokerLinking"),
        Action(label: "launchBrokerCenter"),
        Action(label: "launchAccountSelection"),
        Action(label: "launchAlertQueue")
    ]),
    Section(label: "Themes", actions: [
        Action(label: "setLightTheme"),
        Action(label: "setDarkTheme"),
        Action(label: "setCustomTheme")
    ]),
    Section(label: "Deep Integration", actions: [
        Action(label: "manualAuthenticateAll"),
        Action(label: "manualBalances"),
        Action(label: "manualPositions"),
        Action(label: "manualBuildLinkedBroker")
    ]),
    Section(label: "Debugging", actions: [
        Action(label: "deleteLinkedBrokers"),
        Action(label: "test")
    ]),
    Section(label: "Yahoo", actions: [
        Action(label: "launchOAuthFlow"),
    ])
]

class ExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TradeItOAuthDelegate {
    @IBOutlet weak var table: UITableView!

    let alertManager: TradeItAlertManager = TradeItAlertManager()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        TradeItSDK.linkedBrokerManager.oAuthDelegate = self
        printLinkedBrokers()
    }

    func yahooOAuthFlowCompleted(withLinkedBroker linkedBroker: TradeItLinkedBroker) {
        self.printLinkedBrokers()
        self.alertManager.showAlert(onViewController: self,
                                    withTitle: "Great Success!",
                                    withMessage: "Yahoo: Linked \(linkedBroker.brokerName) via OAuth",
                                    withActionTitle: "OK")

        // TODO: LAUNCH CONFIRMATION SCREEN
    }

    // Mark: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section].actions[indexPath.row].label {
        case "test":
            test()
        case "launchPortfolio":
            TradeItSDK.launcher.launchPortfolio(fromViewController: self)
        case "launchPortfolioForLinkedBrokerAccount":
            guard let linkedBrokerAccount = TradeItSDK.linkedBrokerManager.linkedBrokers.first?.accounts.last else {
                return print("=====> You must link a broker with an account first")
            }
            TradeItSDK.launcher.launchPortfolio(fromViewController: self, forLinkedBrokerAccount: linkedBrokerAccount)
        case "launchPortfolioForAccountNumber": // brkAcct1 is the account number of the Dummy login
            TradeItSDK.launcher.launchPortfolio(fromViewController: self, forAccountNumber: "brkAcct1")
        case "launchTrading":
            TradeItSDK.launcher.launchTrading(fromViewController: self, withOrder: TradeItOrder())
        case "launchTradingWithSymbol":
            let order = TradeItOrder()
            // Any order fields that are set will pre-populate the ticket.
            order.symbol = "CMG"
            order.quantity = 10
            order.action = .sell
            order.type = .stopLimit
            order.limitPrice = 20
            order.stopPrice = 30
            order.expiration = .goodUntilCanceled
            TradeItSDK.launcher.launchTrading(fromViewController: self, withOrder: order)
        case "launchAccountManagement":
            TradeItSDK.launcher.launchAccountManagement(fromViewController: self)
        case "launchOAuthFlow":
            self.launchOAuthFlow()
        case "launchOAuthRelinkFlow":
            self.launchOAuthRelinkFlow()
        case "launchBrokerLinking":
            TradeItSDK.launcher.launchBrokerLinking(
                fromViewController: self,
                onLinked: { linkedBroker in
                    print("=====> Newly linked broker: \(linkedBroker)")
                },
                onFlowAborted: {
                    print("=====> User aborted linking")
                }
            )
        case "launchBrokerCenter":
            TradeItSDK.launcher.launchBrokerCenter(fromViewController: self)
        case "launchAccountSelection":
            TradeItSDK.launcher.launchAccountSelection(
                fromViewController: self,
                title: "Select account to sync",
                onSelected: { selectedLinkedBrokerAccount in
                    print("Selected linked broker account: \(selectedLinkedBrokerAccount)")
                }
            )
        case "setLightTheme":
            TradeItSDK.theme = TradeItTheme.light()
        case "setDarkTheme":
            TradeItSDK.theme = TradeItTheme.dark()
        case "setCustomTheme":
            let customTheme = TradeItTheme()
            customTheme.textColor = UIColor.brown
            TradeItSDK.theme = customTheme
        case "manualAuthenticateAll":
            self.manualAuthenticateAll()
        case "manualBalances":
            self.manualBalances()
        case "manualPositions":
            self.manualPositions()
        case "manualBuildLinkedBroker":
            self.manualBuildLinkedBroker()
        case "launchAlertQueue":
            self.launchAlertQueue()
        case "deleteLinkedBrokers":
            self.deleteLinkedBrokers()
        default:
            return
        }
    }

    func oAuthFlowCompleted(withLinkedBroker linkedBroker: TradeItLinkedBroker) {
        self.printLinkedBrokers()
        self.alertManager.showAlert(onViewController: self,
                                    withTitle: "Great Success!",
                                    withMessage: "Linked \(linkedBroker.brokerName) via OAuth",
                                    withActionTitle: "OK")
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].label
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].actions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "CELL_IDENTIFIER"

        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)

        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier)
        }

        cell?.textLabel?.text = sections[indexPath.section].actions[indexPath.row].label
        
        return cell!
    }

    private func launchYahooOAuthFlow() {
        print("=====> launchYahooOAuthFlow")

        let broker = "dummy"
        TradeItSDK.linkedBrokerManager.getOAuthLoginPopupUrl(
            withBroker: broker,
            deepLinkCallback: "tradeItExampleScheme://completeYahooOAuth",
            onSuccess: { url in
                self.alertManager.showAlert(
                    onViewController: self,
                    withTitle: "OAuthPopupUrl for Linking \(broker)",
                    withMessage: "URL: \(url)",
                    withActionTitle: "Make it so!",
                    onAlertActionTapped: {
                        UIApplication.shared.openURL(NSURL(string:url) as! URL)
                    },
                    showCancelAction: false
                )
            },
            onFailure: { errorResult in
                self.alertManager.showError(errorResult,
                                            onViewController: self)
            }
        )
    }

    private func manualBuildLinkedBroker() {
        TradeItSDK.linkedBrokerManager.linkedBrokers = []

        TradeItSDK.linkedBrokerManager.linkBroker(
            userId: "e041482902073625472a",
            userToken: "R4U3fyK4vjFAMCa9hRwm1qbfgaN669WGkwksirBgKulUcW5WJhqLEGPOhXJ6MsiV6hH3BTIDrkRQXlLCqBj1tEIIODef%2FiJJbMcJ49pKW%2FLlKTcCW2Ygzz%2BrFDIKlq38H8yMa6R%2B%2F0NHuYC6THvD4A%3D%3D",
            broker: "dummy",
            onSuccess: { linkedBroker in
                linkedBroker.accounts = [
                    TradeItLinkedBrokerAccount(
                        linkedBroker: linkedBroker,
                        accountName: "Manual Account Name",
                        accountNumber: "Manual Account Number",
                        balance: nil,
                        fxBalance: nil,
                        positions: [])
                ]

                print("=====> MANUALLY BUILT LINK!")
                self.printLinkedBrokers()
            },
            onFailure: { errorResult in
                print("=====> Failed to manually link: \(errorResult.shortMessage) - \(errorResult.longMessages?.first)")
            }
        )
    }

    private func launchOAuthFlow() {
        let broker = "dummy"
        TradeItSDK.linkedBrokerManager.getOAuthLoginPopupUrl(
            withBroker: broker,
            deepLinkCallback: "tradeItExampleScheme://completeOAuth",
            onSuccess: { url in
                self.alertManager.showAlert(
                    onViewController: self,
                    withTitle: "OAuthPopupUrl for Linking \(broker)",
                    withMessage: "URL: \(url)",
                    withActionTitle: "Make it so!",
                    onAlertActionTapped: {
                        UIApplication.shared.openURL(NSURL(string:url) as! URL)
                    },
                    showCancelAction: false
                )
            },
            onFailure: { errorResult in
                self.alertManager.showError(errorResult,
                                            onViewController: self)
            }
        )
    }

    private func launchOAuthRelinkFlow() {
        guard let linkedBroker = TradeItSDK.linkedBrokerManager.linkedBrokers.first else {
            print("=====> No linked brokers to relink!")

            self.alertManager.showAlert(
                onViewController: self,
                withTitle: "ERROR",
                withMessage: "No linked brokers to relink!",
                withActionTitle: "Oops!"
            )

            return
        }

        TradeItSDK.linkedBrokerManager.getOAuthLoginPopupForTokenUpdateUrl(
            withBroker: linkedBroker.brokerName,
            userId: linkedBroker.linkedLogin.userId ?? "",
            deepLinkCallback: "tradeItExampleScheme://completeOAuth",
            onSuccess: { url in
                self.alertManager.showAlert(
                    onViewController: self,
                    withTitle: "OAuthPopupUrl for Relinking \(linkedBroker.brokerName)",
                    withMessage: "URL: \(url)",
                    withActionTitle: "Make it so!",
                    onAlertActionTapped: {
                        UIApplication.shared.openURL(NSURL(string:url) as! URL)
                    },
                    showCancelAction: false
                )
            },
            onFailure: { errorResult in
                self.alertManager.showError(errorResult,
                                            onViewController: self)
            }
        )
    }

    private func printLinkedBrokers() {
        print("\n\n=====> LINKED BROKERS:")

        for linkedBroker in TradeItSDK.linkedBrokerManager.linkedBrokers {
            let linkedLogin = linkedBroker.linkedLogin
            let userToken = TradeItSDK.linkedBrokerManager.connector.userToken(fromKeychainId: linkedLogin.keychainId)
            print("=====> \(linkedLogin.broker ?? "MISSING BROKER")(\(linkedBroker.accounts.count) accounts)\n    userId: \(linkedLogin.userId ?? "MISSING USER ID")\n    keychainId: \(linkedLogin.keychainId ?? "MISSING KEYCHAIN ID")\n    userToken: \(userToken ?? "MISSING USER TOKEN")")
        }

        print("=====> ===============\n\n")
    }

    private func manualAuthenticateAll() {
        TradeItSDK.linkedBrokerManager.authenticateAll(
            onSecurityQuestion: { securityQuestion, answerSecurityQuestion, cancelQuestion in
                self.alertManager.promptUserToAnswerSecurityQuestion(
                    securityQuestion,
                    onViewController: self,
                    onAnswerSecurityQuestion: answerSecurityQuestion,
                    onCancelSecurityQuestion: cancelQuestion)
            },
            onFinished: {
                self.alertManager.showAlert(
                    onViewController: self,
                    withTitle: "authenticateAll finished",
                    withMessage: "\(TradeItSDK.linkedBrokerManager.linkedBrokers.count) brokers authenticated.",
                    withActionTitle: "OK")
            }
        )
    }

    private func manualBalances() {
        guard let broker = TradeItSDK.linkedBrokerManager.linkedBrokers.first else { return print("=====> You must link a broker first.") }
        guard let account = broker.accounts.first else { return print("=====> Accounts list is empty. Call authenticate on the broker first.") }

        account.getAccountOverview(onSuccess: { balance in
            print(balance ?? "Something went wrong!")
        }, onFailure: { errorResult in
            print(errorResult)
        })
    }

    private func manualPositions() {
        guard let broker = TradeItSDK.linkedBrokerManager.linkedBrokers.first else { return print("=====> You must link a broker first.") }
        guard let account = broker.accounts.first else { return print("=====> Accounts list is empty. Call authenticate on the broker first.") }

        account.getPositions(onSuccess: { positions in
            print(positions.map({ position in
                return position.position
            }))
        }, onFailure: { errorResult in
            print(errorResult)
        })
    }

    private func launchAlertQueue() {
        alertManager.showAlert(
            onViewController: self,
            withTitle: "Alert 1",
            withMessage: "Alert 1",
            withActionTitle: "OK",
            onAlertActionTapped: {}
        )
        let securityQuestion = TradeItSecurityQuestionResult()
        securityQuestion.securityQuestion = "Security Question"
        alertManager.promptUserToAnswerSecurityQuestion(
            securityQuestion, onViewController: self, onAnswerSecurityQuestion: { _ in }, onCancelSecurityQuestion: {}
        )
        alertManager.showAlert(
            onViewController: self,
            withTitle: "Alert 2",
            withMessage: "Alert 2",
            withActionTitle: "OK",
            onAlertActionTapped: {}
        )
    }

    private func deleteLinkedBrokers() -> Void {
        print("=====> Keychain Linked Login count before clearing: \(TradeItSDK.linkedBrokerManager.linkedBrokers.count)")

        let appDomain = Bundle.main.bundleIdentifier;
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)

        let connector = TradeItConnector(apiKey: AppDelegate.API_KEY)
        connector.environment = AppDelegate.ENVIRONMENT

        let linkedLogins = connector.getLinkedLogins() as! [TradeItLinkedLogin]

        for linkedLogin in linkedLogins {
            connector.unlinkLogin(linkedLogin)
        }

        TradeItSDK.linkedBrokerManager.linkedBrokers = []

        print("=====> Keychain Linked Login count after clearing: \(TradeItSDK.linkedBrokerManager.linkedBrokers.count)")
    }
}
