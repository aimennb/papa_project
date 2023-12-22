public class InvoiceManager
{
    private List<Invoice> invoices = new List<Invoice>();

    public Invoice CreateInvoice()
    {
        var invoice = new Invoice { Date = DateTime.Now };
        invoices.Add(invoice);
        return invoice;
    }

    public void AddItemToInvoice(Invoice invoice, InvoiceItem item)
    {
        invoice.Items.Add(item);
    }

    // Ajoutez des méthodes pour supprimer des articles, calculer des totaux, etc.
}
