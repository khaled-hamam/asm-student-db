using System;
using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;

namespace StudentDB_GUI
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public ObservableCollection<string> StudentList;

        public MainWindow()
        {
            StudentList = new ObservableCollection<string>();
            InitializeComponent();
            StudentsListView.ItemsSource = StudentList;
            RefreshList();
        }

        public void RefreshList()
        {
            StudentList.Clear();
            char[] studentRecords = new char[1024];

            AssemblyStudentDB.printStudentsBuffer(studentRecords);

            string records = new string(studentRecords);
            string[] splitRecords = records.Split('/');

            for (int i = 0; i < splitRecords.Length - 1; i += 4)
            {
                int id = splitRecords[i][0];
                string name = splitRecords[i + 1];
                int grade = splitRecords[i + 2][0];
                int section = splitRecords[i + 3][0];

                Student student = new Student { ID = id, Name = name, NumericGrade = grade, Section = section };
                StudentList.Add($"ID: {student.ID}\tName: {student.Name}\tNumeric Grade: {student.NumericGrade}\tSection: {student.Section}");
            }
        }

        public void Search(object sender, RoutedEventArgs e)
        {

        }

        public void Enroll(object sender, RoutedEventArgs e)
        { 
            int ID = int.Parse(StudentIDTextBox.Text);
            string name = StudentNameTextBox.Text;
            int grade = int.Parse(StudentGradeTextBox.Text);
            int section = int.Parse(StudentSectionComboBox.Text);

            AssemblyStudentDB.enrollStudent((char)ID, name, (char)name.Length, (char)grade, (char)section);
            RefreshList();
        }

        public void Delete(object sender, RoutedEventArgs e)
        {
            int ID = int.Parse(DeleteStudentIDTextBox.Text);

            AssemblyStudentDB.deleteStudent((char)ID);
        }

        public void Save(object sender, RoutedEventArgs e)
        {
            int key = int.Parse(SaveDBKeyTextBox.Text);

            AssemblyStudentDB.saveDatabase("database.txt", (char)key);
            RefreshList();
        }

        public void Update(object sender, RoutedEventArgs e)
        {
            int ID = int.Parse(StudentUpdateIDTextBox.Text);
            int grade = int.Parse(StudentUpdateGradeTextBox.Text);

            AssemblyStudentDB.updateGrade((char)ID, (char)grade);
            RefreshList();
        }

        public void Open(object sender, RoutedEventArgs e)
        {
            int key = int.Parse(StudentDBKeyTextBox.Text);

            AssemblyStudentDB.openDatabase("database.txt", (char)key);
            RefreshList();
        }

        public void GenerateSection(object sender, RoutedEventArgs e)
        {
            int section = int.Parse(GenerateSectionComboBox.Text);

            AssemblyStudentDB.generateSectionReport((char)section, $"Section{section}_Report.txt");
        }

        private void Top5(object sender, RoutedEventArgs e)
        {
            char[] studentRecords = new char[1024];

            AssemblyStudentDB.top5Students(studentRecords);

            string records = new string(studentRecords);
            string[] splitRecords = records.Split('/');

            StudentList.Clear();
            for (int i = 0; i < splitRecords.Length - 1; i += 4)
            {
                int id = splitRecords[i][0];
                string name = splitRecords[i + 1];
                int grade = splitRecords[i + 2][0];
                int section = splitRecords[i + 3][0];

                Student student = new Student { ID = id, Name = name, NumericGrade = grade, Section = section };
                StudentList.Add($"ID: {student.ID}\tName: {student.Name}\tNumeric Grade: {student.NumericGrade}\tSection: {student.Section}");
            }
        }
    }
}
