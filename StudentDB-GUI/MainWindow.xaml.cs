using System;
using System.Windows;
namespace StudentDB_GUI
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        public void Enroll(object sender, RoutedEventArgs e)
        { 
            int ID = int.Parse(StudentIDTextBox.Text);
            string name = StudentNameTextBox.Text;
            int grade = int.Parse(StudentIDTextBox.Text);
            int section = int.Parse(StudentSectionComboBox.Text);
            Console.WriteLine(name + " " + ID + " " + grade + " " );
        }

        public void Delete(object sender, RoutedEventArgs e)
        {
            int ID = int.Parse(DeleteStudentIDTextBox.Text);
        }
        public void Save(object sender, RoutedEventArgs e)
        {
            int key = int.Parse(SaveDBKeyTextBox.Text);
        }
        public void Update(object sender, RoutedEventArgs e)
        {
            int ID = int.Parse(StudentUpdateIDTextBox.Text);
            int grade = int.Parse(StudentUpdateGradeTextBox.Text);
        }
        public void Open(object sender, RoutedEventArgs e)
        {
            int key = int.Parse(StudentDBKeyTextBox.Text);
        }
        public void GenerateSection(object sender, RoutedEventArgs e)
        {
            int section = int.Parse(GenerateSectionComboBox.Text);
        }
        private void Top5(object sender, RoutedEventArgs e)
        {

        }
    }
}
