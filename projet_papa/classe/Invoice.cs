public class Invoice
{
    public int InvoiceID { get; set; }
    public DateTime Date { get; set; }
    public List<InvoiceItem> Items { get; set; } = new List<InvoiceItem>();
    public double Total => Items.Sum(item => item.Total);

    // Ajoutez d'autres propriétés de facture, telles que les informations du client, etc.
}
