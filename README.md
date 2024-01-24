# LibraryManagement
Library Management System PL/SQL from ECE 562 course.
﻿﻿This project is an exercise in developing a real-time database system for an application drawn from Library Information Management System. The database schema for this system consists of the following four relations. The primary key of each relation is underlined.
 
Books( book id: number, book_title: varchar2(50), author_id: number, year_of_publication: number, edition: number, status:varchar2(20) )
 
Author( author_id: number, Name: varchar2(30) )
 
Borrower ( borrower_id: number, name: varchar2(30), status: varchar2(20) )
 
Issue( book_id: number, borrower_id: number, issue_date: date, return_date: date)
 
Rules/Constraints:
 
1. Status in the Books relation can have only two values: charged /not charged.
 
2. Status in the Borrower relation can be either student or faculty.
 
3. Only a maximum of two books can be issued to a student and a maximum of three books to a faculty member at a time.
 
4. Books are to be returned within five days of their date of issue. Otherwise, a fine of $5 per day is charged for late return.
 
5. There is only one copy of every book. If a book is already issued it cannot be issued to another person.
6. Assume a book cannot be renewed by a borrower at the time of returning the book. Only one transaction is supposed to be executed by a borrower; either returning a book or getting a book issued.
 
7. Whenever a book is issued, a new record is inserted to the Issue table and a NULL value is assigned to return_date. When a borrower returns the book, this field is updated to the date of return.
 
Triggers:
 
1. Implement a trigger that enforces rule 3 in the database. Name this trigger as trg_maxbooks.
 
2. Implement a trigger that changes the status in the Books table to 'charged' whenever a book is issued, i.e., when a new tuple is added to the Issue table. Name this trigger as trg_charge.
 
3. Implement a trigger that changes the status in the Books table to 'not charged' whenever a borrower returns the book. Name this trigger as trg_notcharge.
 
Functions:
 
1. Write a function (name it fun_issue_book) that takes the following arguments: borrower_id, book_id, and current_date. This function issues a book to the requester if it is not already charged, otherwise the book is not issued. The current_date corresponds to issue_date if the book is issued. The function will return ' 1' if the book is issued to the requester, otherwise it will return '0'. This function is called by the following function fun_issue_anyedition.
 
2. Write a function (name it fun_issue_anyedition) that takes the following input arguments: borrower_id, book_title, author_name and current_date. This function calls the above function fun_issue_book tor issuing of the latest edition of the requested book. In case, the latest edition is not available, this function then determines the next older edition that is currently available in the library which can be issued. If no edition of the requested book is currently available, the request is not served. The function returns ‘1’ if the request is satisfied, otherwise it returns ‘0’
 
3. Write a function (name it fun_return_book) that takes book_id and return_date as inputs and returns the book to the library by updating appropriate tables. The function returns '1' if the operation is successful; otherwise, it returns '0'.
 
Procedures:
 
1. Write a procedure (name it pro_print_borrower) to print out current borrowers' list in the following format. The number of days equals to the difference between the issue_date and today's date.
 
Borrower Name           Book Title                  <= 5 days              <= 10 days             <= 15 days      >15 days    
   -----------       ----------------             ---------------          -----------------        ------------------     ---------------
Adah Talbot     Fundamentals of Democracy                                                                                       100
Adah Talbot     Programming in Unix                   1
 
 
2. Write a procedure (name it pro_list_borr) to print out the names of the borrower who have not returned the books yet (including both overdue and not overdue). Also print the book_id and issue_date.
 
NOTE: Your project should NOT use any temporary table otherwise our testing script will fail and you will get no grades. (Internally you can create temporary tables, but not explicitly declared in create command)
 
Execution phase and what to submit:
For submission, the following SQL commands and execution code must be included as one file, in the order they are listed. Name this file as <your user name>.sql.
SPOOL your-user-name-output.txt;  /* output is sent to your-user-name-output.txt file */
SET SERVEROUTPUT ON

EXEC DBMS_OUTPUT.PUT_LINE('put your comment here, can be used anywhere');
/* For every step below, print out a comment indicating the type of execution and the expected output of that step. This is output is needed for the TA to grade your project*/
 
• Use REM (remarks statement) at the beginning of this file to put your full name.
• Write SQL commands for creating the tables and defining integrity constraints
• Write SQL code for functions
• Write SQL code for procedures
• Write SQL code for triggers
• Populate the Books, Author and Borrower tables with the data shown in Appendix A.
• Include the command @TA_test_data.  /* This file will be created by the TA and will contain data to test your project i.e. to test your procedures, functions and triggers primarily via loading the Issue table using fun_issue_book. See Appendix B for an example. */
• Use the function fun_issue_anyedition to further populate the Issue table by inserting the following records in your sample database for testing. This function must take all the four parameters.
 
Borrower_id​    Book_title ​​​Author ​​​Date 
 
2​​    DATA MANAGEMENT ​C.J. DATES​​​3/3/05
4​​    CALCULUS​​H. ANTON​​​3/4/05
5​               ORACLE​​​ORACLE PRESS​​3/4/05
10​​    IEEE MULTIMEDIA​IEEE​​​            2/27/05
2​​    MIS MANAGEMENT ​C.J. CATES​​​5/3/05
4​​    CALCULUS II​​H. ANTON​​​3/4/05
10​                ORACLE​​​ORACLE PRESS​​3/4/05
5​​    IEEE MULTIMEDIA​IEEE​​​           2/26/05
2​​    DATA SRUCTURE ​W. GATES​​​3/3/05
4​​   CALCULUS III​​H. ANTON​​​4/4/05
11​               ORACLE​​​ORACLE PRESS​​3/8/05
6​​    IEEE MULTIMEDIA​IEEE​​​           2/17/05
 
• Execute pro_print_borrower.
 
• Use the function fun_return_book() to return books with book_id 1,2, 4, 10. Also, specify the returns date as the second parameter.
 
• Print the Issue table.
 
• Execute pro_list_borr.
 
• You need to keep track and finally print out the total number of borrowers’ requests that could not be fulfilled due to either exceeding the maximum limit on borrowing or due to unavailability of any edition of the desired book.
 
• At the end of your <your user name>.sql file, you must include statements to drop all the tables, triggers, functions and procedures to ensure proper testing and grading of your project.
 
SPOOL OFF;
 
 
Note:
1. You must use PL/SQL (Oracle procedural extension to SQL) to write your triggers, procedures and functions. Use the ORACLE Reference book mentioned in the handouts given in the first week of the class.
 
2. Please use the same version of Oracle that is installed on ECN. No grade will be awarded on the queries or procedures that cannot run on Oracle version installed on ECN machines.
 
Note for submission:
Submit your <your user name>.sql file using link on the Brightspace web site.

Appendix A
-- Insert records into Author
insert into Author values(1,'C.J. DATES');
insert into Author values(2,'H. ANTON');
insert into Author values(3,'ORACLE PRESS');
insert into Author values(4,'IEEE');
insert into Author values(5,'C.J. CATES');
insert into Author values(6,'W. GATES');
insert into Author values(7,'CLOIS KICKLIGHTER');
insert into Author values(8,'J.R.R. TOLKIEN');
insert into Author values(9,'TOM CLANCY');
insert into Author values(10,'ROGER ZELAZNY');
 
-- Insert records into Books
insert into Books values(1,'DATA MANAGEMENT',1,1998,3,'not charged');
insert into Books values(2,'CALCULUS',2,1995,7,'not charged');
insert into Books values(3,'ORACLE',3,1999,8,'not charged');
insert into Books values(4,'IEEE MULTIMEDIA',4,2001,1,'not charged');
insert into Books values(5,'MIS MANAGEMENT',5,1990,1,'not charged');
insert into Books values(6,'CALCULUS II',2,1997,3,'not charged');
insert into Books values(7,'DATA STRUCTURE',6,1992,1,'not charged');
insert into Books values(8,'CALCULUS III',2,1999,1,'not charged');
insert into Books values(9,'CALCULUS III',2,2000,2,'not charged');
insert into Books values(10,'ARCHITECTURE',7,1977,1,'not charged');
insert into Books values(11,'ARCHITECTURE',7,1980,2,'not charged');
insert into Books values(12,'ARCHITECTURE',7,1985,3,'not charged');
insert into Books values(13,'ARCHITECTURE',7,1990,4,'not charged');
insert into Books values(14,'ARCHITECTURE',7,1995,5,'not charged');
insert into Books values(15,'ARCHITECTURE',7,2000,6,'not charged');
insert into Books values(16,'THE HOBBIT',8,1960,1,'not charged');
insert into Books values(17,'THE BEAR AND THE DRAGON',9,2000,1,'not charged');
insert into Books values(18,'NINE PRINCES IN AMBER',10,1970,1,'not charged');
 
-- Insert records into Borrower
insert into Borrower values(1,'BRAD KICKLIGHTER','student');
insert into Borrower values(2,'JOE STUDENT','student');
insert into Borrower values(3,'GEDDY LEE','student');
insert into Borrower values(4,'JOE FACULTY','faculty');
insert into Borrower values(5,'ALBERT EINSTEIN','faculty');
insert into Borrower values(6,'MIKE POWELL','student');
insert into Borrower values(7,'DAVID GOWER','faculty');
insert into Borrower values(8,'ALBERT SUNARTO','student');
insert into Borrower values(9,'GEOFFERY BYCOTT','faculty');
insert into Borrower values(10,'JOHN KACSZYCA','student');
insert into Borrower values(11,'IAN LAMB','faculty');
insert into Borrower values(12,'ANTONIO AKE','student');
Appendix B (TA_test_data)
 
This data will use a series of following type of calls to fun_issue_book to populate the Issue table:
 
fun_issue_book(7, 1, to_date('02/10/03','MM/DD/YY'));
