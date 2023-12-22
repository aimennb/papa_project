CREATE TABLE Products (
    ProductID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name TEXT NOT NULL,
    UnitPrice REAL NOT NULL,
    -- Vous pouvez ajouter plus d'attributs ici comme le poids, le fournisseur, etc.
);

CREATE TABLE Invoices (
    InvoiceID INTEGER PRIMARY KEY AUTOINCREMENT,
    Date TEXT NOT NULL,
    Total REAL NOT NULL
    -- D'autres informations de la facture
);

CREATE TABLE InvoiceItems (
    ItemID INTEGER PRIMARY KEY AUTOINCREMENT,
    InvoiceID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    Quantity REAL NOT NULL,
    Price REAL NOT NULL,
    Total REAL NOT NULL,
    FOREIGN KEY (InvoiceID) REFERENCES Invoices (InvoiceID),
    FOREIGN KEY (ProductID) REFERENCES Products (ProductID)
);
