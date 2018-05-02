using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;

namespace StudentDB_GUI
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public ObservableCollection<Student> StudentList;

        public MainWindow()
        {
            StudentList = new ObservableCollection<Student>();
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

            for (int i = 0; i < splitRecords.Length - 1; i += 5)
            {
                int id = splitRecords[i][0];
                string name = splitRecords[i + 1];
                int grade = splitRecords[i + 2][0];
                char alphabetGrade = splitRecords[i + 3][0];
                int section = splitRecords[i + 4][0];

                Student student = new Student { ID = id, Name = name, NumericGrade = grade, AlphabeticGrade = alphabetGrade, Section = section };
                StudentList.Add(student);
            }
        }

        public void Search(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrEmpty(searchQuery.Text))
            {
                RefreshList();
                return;
            }

            int searchID = int.Parse(searchQuery.Text);
            char[] studentRecord = new char[100];

            AssemblyStudentDB.printStudent((char)searchID, studentRecord);
            string recordString = new string(studentRecord);

            string[] fields = recordString.Split(' ');
            if (fields.Length != 5)
                return;

            StudentList.Clear();

            Student student = new Student { ID = int.Parse(fields[0]), Name = fields[1], NumericGrade = int.Parse(fields[2]), AlphabeticGrade = fields[3][0], Section = int.Parse(fields[4]) };
            StudentList.Add(student);
        }

        public void Enroll(object sender, RoutedEventArgs e)
        {
            StudentIDTextBox.Text = (StudentIDTextBox != null) ? StudentIDTextBox.Text.Trim() : "";
            StudentNameTextBox.Text = (StudentNameTextBox != null) ? StudentNameTextBox.Text.Trim() : "";
            StudentGradeTextBox.Text = (StudentGradeTextBox != null) ? StudentGradeTextBox.Text.Trim() : "";
            StudentSectionComboBox.Text = (StudentSectionComboBox != null) ? StudentSectionComboBox.Text.Trim() : "";
            if (StudentIDTextBox.Text != "" && StudentNameTextBox.Text != "" && StudentGradeTextBox.Text != "" && StudentSectionComboBox.Text != "")
            {
                int ID = int.Parse(StudentIDTextBox.Text);
                string name = StudentNameTextBox.Text;
                int grade = int.Parse(StudentGradeTextBox.Text);
                int section = int.Parse(StudentSectionComboBox.Text);
                if (ID > 0 && ID < 256 && grade <= 100 && grade >= 0)
                {
                    try
                    {
                        AssemblyStudentDB.enrollStudent((char)ID, name, (char)name.Length, (char)grade, (char)section);
                    }
                    catch
                    {
                        Console.WriteLine("Error in enrollStudent");
                    }
                    RefreshList();
                }
                else
                    MessageBox.Show("Enter Valid Number between 1 and 255 ");
            }
            else
                MessageBox.Show("No empty Values");
            StudentIDTextBox.Clear();
            StudentNameTextBox.Clear();
            StudentGradeTextBox.Clear();
            StudentSectionComboBox.SelectedIndex = -1;
        }

        public void Delete(object sender, RoutedEventArgs e)
        {
            DeleteStudentIDTextBox.Text = (DeleteStudentIDTextBox != null) ? DeleteStudentIDTextBox.Text.Trim() : "";
            if (DeleteStudentIDTextBox.Text != "")
            {
                int ID = int.Parse(DeleteStudentIDTextBox.Text);
                if (ID > 0 && ID < 256)
                {
                    try
                    {
                        AssemblyStudentDB.deleteStudent((char)ID);
                    }
                    catch
                    {
                        Console.WriteLine("Error in deleteStudent");
                    }
                }
            else
                MessageBox.Show("Enter Valid Number between 1 and 255");
            }
            else
                MessageBox.Show("No Empty Values");
            DeleteStudentIDTextBox.Clear();
        }


        public void Save(object sender, RoutedEventArgs e)
        {
            SaveDBKeyTextBox.Text = (SaveDBKeyTextBox != null) ? SaveDBKeyTextBox.Text.Trim() : "";
            if (SaveDBKeyTextBox.Text != "")
            {
                int key = int.Parse(SaveDBKeyTextBox.Text);
                if (key > 0 && key < 256)
                {
                    try
                    {
                        AssemblyStudentDB.saveDatabase("database.txt", (char)key);
                    }
                    catch
                    {
                        Console.WriteLine("Error in saveDatabase");
                    }
                    RefreshList();
                }
                else
                    MessageBox.Show("Enter Valid Number between 1 and 255");
            }
            else
                MessageBox.Show("No empty Values");
            SaveDBKeyTextBox.Clear();
        }

        public void Update(object sender, RoutedEventArgs e)
        {
            StudentUpdateIDTextBox.Text = (StudentUpdateIDTextBox != null) ? StudentUpdateIDTextBox.Text.Trim() : "";
            StudentUpdateGradeTextBox.Text = (StudentUpdateGradeTextBox != null) ? StudentUpdateGradeTextBox.Text.Trim() : "";

            if (StudentUpdateIDTextBox.Text != "" && StudentUpdateGradeTextBox.Text != "")
            {
                int ID = int.Parse(StudentUpdateIDTextBox.Text);
                int grade = int.Parse(StudentUpdateGradeTextBox.Text);
                if (ID > 0 && ID < 256 && grade <= 100 && grade >= 0)
                {
                    try
                    {
                        AssemblyStudentDB.updateGrade((char)ID, (char)grade);
                    }
                    catch
                    {
                        Console.WriteLine("Error in updateGrade");
                    }
                  
                    RefreshList();
                }
                else
                    MessageBox.Show("Enter Valid Number between 1 and 255");
                StudentUpdateGradeTextBox.Clear();
                StudentUpdateIDTextBox.Clear();
            }
            else
                MessageBox.Show("No empty values");
        }

        public void Open(object sender, RoutedEventArgs e)
        {
            StudentDBKeyTextBox.Text = (StudentDBKeyTextBox != null) ? StudentDBKeyTextBox.Text.Trim() : "";
            if (StudentDBKeyTextBox.Text != "")
            {
                int key = int.Parse(StudentDBKeyTextBox.Text);
                if (key > 0 && key < 256)
                {
                    try
                    {
                        AssemblyStudentDB.openDatabase("database.txt", (char)key);
                    }
                    catch
                    {
                        Console.WriteLine("Error in openDatabase");
                    }
                   
                    RefreshList();
                }
                else
                    MessageBox.Show(" Enter Valid Number between 1 and 255");
            }
            else
                MessageBox.Show("No empty values");
            StudentDBKeyTextBox.Clear();

        }

        public void GenerateSection(object sender, RoutedEventArgs e)
        {
            GenerateSectionComboBox.Text = (GenerateSectionComboBox != null) ? GenerateSectionComboBox.Text.Trim() : "";
            if (GenerateSectionComboBox.Text != "")
            {
                int section = int.Parse(GenerateSectionComboBox.Text);
                try
                {
                AssemblyStudentDB.generateSectionReport((char)section, $"Section{section}_Report.txt");
                }
                catch
                {
                    Console.WriteLine("Error in generateSectionReport");
                }
            }
            else
                MessageBox.Show("No empty Values");
            GenerateSectionComboBox.SelectedIndex = -1;
        }

        private void Top5(object sender, RoutedEventArgs e)
        {
            char[] studentRecords = new char[1024];
            try
            {
                AssemblyStudentDB.top5Students(studentRecords);
            }
            catch
            {
                Console.WriteLine("Error in top5Students");
            }
           

            string records = new string(studentRecords);
            string[] splitRecords = records.Split('/');

            StudentList.Clear();
            for (int i = 0; i < splitRecords.Length - 1; i += 5)
            {
                int id = splitRecords[i][0];
                string name = splitRecords[i + 1];
                int grade = splitRecords[i + 2][0];
                char alphabetGrade = splitRecords[i + 3][0];
                int section = splitRecords[i + 4][0];

                Student student = new Student { ID = id, Name = name, NumericGrade = grade, AlphabeticGrade = alphabetGrade, Section = section };
                StudentList.Add(student);
            }
        }
    }
}
