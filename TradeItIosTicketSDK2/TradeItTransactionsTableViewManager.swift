class TradeItTransactionsTableViewManager: NSObject, UITableViewDelegate, UITableViewDataSource {
    private var _table: UITableView?
    private var refreshControl: UIRefreshControl?
    var transactionsTable: UITableView? {
        get {
            return _table
        }
        
        set(newTable) {
            if let newTable = newTable {
                newTable.dataSource = self
                newTable.delegate = self
                addRefreshControl(toTableView: newTable)
                _table = newTable
            }
        }
    }
    private let HEADER_HEIGHT = 36
    private var transactions: [TradeItTransaction] = []
    private var linkedBrokerAccount: TradeItLinkedBrokerAccount
    
    weak var delegate: TradeItTransactionsTableDelegate?
    
    init(linkedBrokerAccount: TradeItLinkedBrokerAccount) {
        self.linkedBrokerAccount = linkedBrokerAccount
    }
    
    func updateTransactions(_ transactions: [TradeItTransaction]) {
        self.transactions = transactions
        self.transactionsTable?.reloadData()
    }
    
    func initiateRefresh() {
        self.refreshControl?.beginRefreshing()
        self.delegate?.refreshRequested(
            onRefreshComplete: {
                self.refreshControl?.endRefreshing()
            }
        )
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TRADE_IT_TRANSACTION_HEADER_ID") ?? UITableViewCell()
        let header = cell.contentView
        TradeItThemeConfigurator.configureTableHeader(header: header)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(HEADER_HEIGHT)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TRADE_IT_TRANSACTION_CELL_ID") as? TradeItTransactionTableViewCell
            , let transaction = self.transactions[safe: indexPath.row] else {
                return UITableViewCell()
        }
        
        cell.populate(withTransaction: transaction, andAccountBasecurrency: self.linkedBrokerAccount.accountBaseCurrency)
        return cell
    }
    
    // MARK: private
    private func addRefreshControl(toTableView tableView: UITableView) {
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing...")
        refreshControl.addTarget(
            self,
            action: #selector(initiateRefresh),
            for: UIControlEvents.valueChanged
        )
        TradeItThemeConfigurator.configure(view: refreshControl)
        tableView.addSubview(refreshControl)
        self.refreshControl = refreshControl
    }

}

protocol TradeItTransactionsTableDelegate: class {
    func refreshRequested(onRefreshComplete: @escaping () -> Void)
}
