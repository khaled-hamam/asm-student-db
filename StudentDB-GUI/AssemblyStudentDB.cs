using System.Runtime.InteropServices;

namespace StudentDB_GUI
{
    class AssemblyStudentDB
    {
        const string StudentDBdll = "StudentDB.dll";

        [DllImport(StudentDBdll)]
        public static extern void enrollStudent(char id, string name, char nameSize, char grade, char section);

        [DllImport(StudentDBdll)]
        public static extern void saveDatabase(string FName, char KEY);

        [DllImport(StudentDBdll)]
        public static extern void openDatabase(string FName, char KEY);

        [DllImport(StudentDBdll)]
        public static extern void updateGrade(char studentID, char newGrade);

        [DllImport(StudentDBdll)]
        public static extern void deleteStudent(char studentID);

        [DllImport(StudentDBdll)]
        public static extern void printStudent(char studentID, [Out] char[] studentData);

        [DllImport(StudentDBdll)]
        public static extern void generateSectionReport(char sectionNumber, string fileName);

        [DllImport(StudentDBdll)]
        public static extern void top5Students([Out] char[] studentsData);

        [DllImport(StudentDBdll)]
        public static extern void printStudentsBuffer([Out] char[] studentsBuffer);
    }
}
