using System.Windows;

namespace FruitStoreApp
{
    public partial class MainWindow : Window
    {
        private Invoice currentInvoice;

        public MainWindow()
        {
            InitializeComponent();
            NewInvoice();
        }

        // Gère le clic pour créer une nouvelle facture
        private void NewInvoice_Click(object sender, RoutedEventArgs e)
        {
            NewInvoice();
        }

        // Initialise une nouvelle facture et la lie à l'interface utilisateur
        private void NewInvoice()
        {
            currentInvoice = new Invoice { Date = DateTime.Now };
            InvoiceItemsListView.ItemsSource = currentInvoice.Items;
            UpdateTotal();
        }

        // Met à jour le total affiché dans l'interface utilisateur
        private void UpdateTotal()
        {
            TotalTextBlock.Text = currentInvoice.Total.ToString("C");
        }
        
        // Vous devrez ajouter des méthodes pour ajouter/supprimer des articles, etc.
    }
}
