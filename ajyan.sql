SPOOL ajyan-output.txt
SET SERVEROUTPUT ON

-- Use REM (remarks statement) at the beginning of this file to put your full name.
REM Alex Yan

-- define global variable for unfulfilled requests
CREATE OR REPLACE PACKAGE requests IS
    unfulfilled NUMBER := 0;
END;
/
-- Write SQL commands for creating the tables and defining integrity constraints

CREATE TABLE Author (
    author_id NUMBER PRIMARY KEY,
    Name VARCHAR2(30)
);

CREATE TABLE Borrower (
    borrower_id NUMBER PRIMARY KEY,
    name VARCHAR2(30),
    status VARCHAR2(20) CHECK (status IN ('student', 'faculty'))
);

CREATE TABLE Books (
    book_id NUMBER PRIMARY KEY,
    book_title VARCHAR2(50),
    author_id NUMBER,
    year_of_publication NUMBER,
    edition NUMBER,
    status VARCHAR2(20) CHECK (status IN ('charged', 'not charged')),
    FOREIGN KEY (author_id) REFERENCES Author (author_id)
);

CREATE TABLE Issue (
    book_id NUMBER,
    borrower_id NUMBER,
    issue_date DATE,
    return_date DATE,
    FOREIGN KEY (book_id) REFERENCES Books (book_id),
    FOREIGN KEY (borrower_id) REFERENCES Borrower (borrower_id)
);

-- Write SQL code for functions

-- fun_issue_book

CREATE OR REPLACE FUNCTION fun_issue_book(
    borrowerID NUMBER,
    bookID NUMBER,
    curr_date DATE
) RETURN NUMBER
IS
    book_status VARCHAR2(20);
BEGIN
    
    -- Get the status of the book
    SELECT status INTO book_status FROM Books WHERE Books.book_id = bookID;

    -- Check if the book is not charged
    IF book_status = 'not charged' THEN
        -- Issue the book
        BEGIN
            INSERT INTO Issue (book_id, borrower_id, issue_date, return_date)
            VALUES (bookID, borrowerID, curr_date, NULL);

            EXCEPTION   
                WHEN OTHERS THEN   
                    RETURN 0;
        END;
        DBMS_OUTPUT.PUT_LINE('Issued book ' || bookID || ' to borrower ' || borrowerID);
        RETURN 1;
    ELSE
        RETURN 0;


    END IF;
END;
/

-- fun_issue_anyedition
CREATE OR REPLACE FUNCTION fun_issue_anyedition(
    borrowerID NUMBER,
    bookTitle VARCHAR2,
    authorName VARCHAR2,
    curr_date DATE
) RETURN NUMBER
IS 
n NUMBER;
bookID NUMBER;
BEGIN
    -- Determine latest edition of the requrested book that is available
    BEGIN
        SELECT book_id INTO bookID
        FROM Books b
        JOIN Author a ON b.author_id = a.author_id
        WHERE b.book_title = bookTitle AND a.name = authorName
        AND b.status = 'not charged' 
        AND b.edition = (SELECT max(b2.edition) FROM Books b2 
                        JOIN Author a ON b.author_id = a.author_id
                        WHERE b2.book_title = bookTitle AND a.name = authorName
                        AND b2.status = 'not charged');
        EXCEPTION
            WHEN no_data_found THEN
                DBMS_OUTPUT.PUT_LINE('Error: ' || bookTitle || ' by ' || authorName || ' is unavailable to issue to borrower ' || borrowerID);
                requests.unfulfilled := requests.unfulfilled + 1;
                bookID := NULL;
    END;
    IF bookID IS NOT NULL THEN
        RETURN fun_issue_book(borrowerID, bookID, curr_date);
    ELSE
        RETURN 0;
    END IF;
END;
/
-- fun_return_book

CREATE OR REPLACE FUNCTION fun_return_book(
    bookID NUMBER,
    returnDate DATE
) RETURN NUMBER
IS retDate DATE;
BEGIN 
    BEGIN
        SELECT return_date INTO retDate FROM Issue WHERE book_id = bookID;

        EXCEPTION
            WHEN no_data_found THEN
                DBMS_OUTPUT.PUT_LINE('Error: Book ' || bookID || ' has not been Issued');
                RETURN 0;
    END;

    IF retDate IS NULL THEN
        BEGIN
            UPDATE Issue SET return_date = returnDate WHERE book_id = bookID;

            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Failed to return book ' || bookID);
        END;

        DBMS_OUTPUT.PUT_LINE('Returned book ' || bookID || ' on ' || returnDate);
        RETURN 1;
    ELSE 
        DBMS_OUTPUT.PUT_LINE('Error: Book ' || bookID || 'has already been returned.');
        RETURN 0;
    END IF;
END;
/
-- Write SQL code for procedures

-- pro_print_borrower
CREATE OR REPLACE PROCEDURE pro_print_borrower IS
    v_days_difference NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Borrower Name       |    Book Title   |<= 5 days|<= 10 days|<= 15 days|> 15 days'
    );

    DBMS_OUTPUT.PUT_LINE(
        '-------------------- ---------------------- --------- --------- --------- ------'
    );

    FOR borrower_rec IN (SELECT
                            b.name AS Name,
                            bk.book_title,
                            i.issue_date,
                            i.book_id,
                            i.return_date
                        FROM
                            Borrower b
                        JOIN
                            Issue i ON b.borrower_id = i.borrower_id
                        JOIN
                            Books bk ON i.book_id = bk.book_id) 
    LOOP
        -- Calculate the number of days between issue_date and today
        v_days_difference := SYSDATE - borrower_rec.issue_date;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(borrower_rec.Name, 20) || ' | ' ||
            RPAD(borrower_rec.book_title, 20) || ' | ' ||
            RPAD(CASE WHEN v_days_difference <= 5 THEN TO_CHAR(v_days_difference) ELSE ' ' END, 3) || ' | ' ||
            RPAD(CASE WHEN v_days_difference > 5 AND v_days_difference <= 10 THEN TO_CHAR(v_days_difference) ELSE ' ' END, 3) || ' | ' ||
            RPAD(CASE WHEN v_days_difference > 10 AND v_days_difference <= 15 THEN TO_CHAR(v_days_difference) ELSE ' ' END, 3) || ' | ' ||
            RPAD(CASE WHEN v_days_difference > 15 THEN TO_CHAR(v_days_difference) ELSE ' ' END, 10)
        );
    END LOOP;
END;
/

-- pro_list_borr
-- Create the pro_list_borr procedure
CREATE OR REPLACE PROCEDURE pro_list_borr IS
BEGIN
    -- Print header
    DBMS_OUTPUT.PUT_LINE('Borrower Name             Book ID       Issue Date');
    DBMS_OUTPUT.PUT_LINE('--------------            ---------     ------------');

    -- Loop through the cursor and print the results
    FOR not_returned_rec IN (SELECT
                                b.name,
                                i.book_id,
                                i.issue_date
                            FROM
                                Borrower b
                            JOIN
                                Issue i ON b.borrower_id = i.borrower_id
                            WHERE i.return_date IS NULL) 
    LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(not_returned_rec.name, 25) || ' ' ||
            RPAD(TO_CHAR(not_returned_rec.book_id), 13) || ' ' ||
            TO_CHAR(not_returned_rec.issue_date)
        );
    END LOOP;
END;
/
-- Write SQL code for triggers 

-- max 2 books to students and max 3 books to faculty
CREATE OR REPLACE TRIGGER trg_maxbooks
BEFORE INSERT ON Issue
FOR EACH ROW
DECLARE
    v_borrower_status VARCHAR2(20);
    n_checked_out NUMBER;
BEGIN
    SELECT status INTO v_borrower_status FROM Borrower WHERE borrower_id = :NEW.borrower_id;
    SELECT COUNT(*) INTO n_checked_out FROM Issue WHERE borrower_id = :NEW.borrower_id AND return_date IS NULL;

    IF (v_borrower_status = 'student' AND n_checked_out >= 2) OR (v_borrower_status = 'faculty' AND n_checked_out >= 3) THEN
        DBMS_OUTPUT.PUT_LINE('Error: Max number of books exceeded for borrower ' || :NEW.borrower_id || ', unable to issue ' || :NEW.book_id);
        requests.unfulfilled := requests.unfulfilled + 1;
        RAISE_APPLICATION_ERROR(-20000, 'Maximum number of books exceeded.');
    END IF;
END;
/

-- trig_charge
CREATE OR REPLACE TRIGGER trg_charge
AFTER INSERT ON Issue
FOR EACH ROW
BEGIN
    -- Change the status of the book to 'charged'
    UPDATE Books SET status = 'charged' WHERE book_id = :NEW.book_id;
END;
/

-- trg_notcharge
CREATE OR REPLACE TRIGGER trg_notcharge
BEFORE UPDATE ON Issue
FOR EACH ROW
BEGIN
    -- Change the status of the book to 'not charged'
    IF :NEW.return_date IS NOT NULL THEN
        UPDATE Books SET status = 'not charged' WHERE book_id = :NEW.book_id;
    END IF;
END;
/

-- Populate the Books, Author and Borrower tables with the data shown in Appendix A.
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
-- Include the command @TA_test_data. 
@TA_test_data
-- Use the function fun_issue_anyedition to further populate the Issue table by inserting 
-- the following records in your sample database for testing. 
DECLARE
    result NUMBER;
BEGIN
    result := fun_issue_anyedition(2, 'DATA MANAGEMENT', 'C.J. DATES', to_date('3/3/05','MM/DD/YY'));
    result := fun_issue_anyedition(4, 'CALCULUS', 'H. ANTON', to_date('3/4/05','MM/DD/YY'));
    result := fun_issue_anyedition(5, 'ORACLE', 'ORACLE PRESS', to_date('3/4/05','MM/DD/YY'));
    result := fun_issue_anyedition(10, 'IEEE MULTIMEDIA', 'IEEE', to_date('2/27/05','MM/DD/YY'));
    result := fun_issue_anyedition(2, 'MIS MANAGEMENT', 'C.J. CATES', to_date('5/3/05','MM/DD/YY'));
    result := fun_issue_anyedition(4, 'CALCULUS II', 'H. ANTON', to_date('3/4/05','MM/DD/YY'));
    result := fun_issue_anyedition(10, 'ORACLE', 'ORACLE PRESS', to_date('3/4/05','MM/DD/YY'));
    result := fun_issue_anyedition(5, 'IEEE MULTIMEDIA', 'IEEE', to_date('2/26/05','MM/DD/YY'));
    result := fun_issue_anyedition(2, 'DATA STRUCTURE', 'W. GATES', to_date('3/3/05','MM/DD/YY'));
    result := fun_issue_anyedition(4, 'CALCULUS III', 'H. ANTON', to_date('4/4/05','MM/DD/YY'));
    result := fun_issue_anyedition(11, 'ORACLE', 'ORACLE PRESS', to_date('3/8/05','MM/DD/YY'));
    result := fun_issue_anyedition(6, 'IEEE MULTIMEDIA', 'IEEE', to_date('2/17/05','MM/DD/YY'));
    
    -- Execute pro_print_borrower-4
    DBMS_OUTPUT.PUT_LINE(chr(10)|| 'pro_print_borrower');
    pro_print_borrower;
    -- Return Books
    DBMS_OUTPUT.PUT_LINE(chr(10));
    result := fun_return_book(1,SYSDATE);
    result := fun_return_book(2,SYSDATE);
    result := fun_return_book(4,SYSDATE);
    result := fun_return_book(10,SYSDATE);
    -- Print Issue table
    DBMS_OUTPUT.PUT_LINE(chr(10));
    DBMS_OUTPUT.PUT_LINE('Issue Table:');
    DBMS_OUTPUT.PUT_LINE('Book ID           Borrower ID        Issue Date       Return Date');
    DBMS_OUTPUT.PUT_LINE('-------           -----------        ----------       -----------');
    for rec IN (SELECT book_id, borrower_id, issue_date, return_date FROM Issue) LOOP
            DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.book_id, 20) || ' ' ||
            RPAD(rec.borrower_id, 15) || ' ' ||
            RPAD(TO_CHAR(rec.issue_date),18) ||
            TO_CHAR(rec.return_date)
        );
    END LOOP;
    -- Execute pro_list_borr
    DBMS_OUTPUT.PUT_LINE(chr(10) || 'pro_list_borr');
    pro_list_borr;

    DBMS_OUTPUT.PUT_LINE(chr(10));
    DBMS_OUTPUT.PUT_LINE('Number of unfulfilled requests: ' || requests.unfulfilled);
END;
/
-- DROP tables, triggers, functions, procedures
DROP TABLE Issue;
DROP TABLE Books;
DROP TABLE Author;
DROP TABLE Borrower;

DROP FUNCTION fun_return_book;
DROP FUNCTION fun_issue_book;
DROP FUNCTION fun_issue_anyedition;

DROP PROCEDURE pro_list_borr;
DROP PROCEDURE pro_print_borrower;

DROP PACKAGE requests;
SPOOL OFF;