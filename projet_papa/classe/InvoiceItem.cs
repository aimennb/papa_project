public class InvoiceItem
{
    public int ItemID { get; set; }
    public int InvoiceID { get; set; }
    public Product Product { get; set; }
    public double Quantity { get; set; }
    public double Price => Product.UnitPrice;
    public double Total => Quantity * Price;
}
