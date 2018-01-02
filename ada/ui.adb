with Ada.Integer_Text_Io; use Ada.Integer_Text_Io;
with Ada.Text_Io; use Ada.Text_Io;
with model; use model;
with Master; use Master; 



package body UI is

        procedure CLS is
        begin
            Put(ASCII.ESC & "[2J");
        end CLS;

        task body keyListener is
            a : Character;
        begin
            Get(a);
            NOKEY := False;
        end keyListener;

        procedure showLogsForTrains is
            iter : Integer := 1;
            cursor : model.StrVectors.Cursor;
            keyL : keyListener;
        begin
            NOKEY := True;
            while NOKEY loop
                CLS;
                iter := 1;
                loop
                    exit when iter > nooTrains;
                    cursor := trains(iter).logs.Last;
                    Put_Line(trains(iter).logs(cursor));

                    iter := iter + 1;
                end loop;

                delay 0.1;
            end loop;

        end showLogsForTrains;

        procedure showAllLogs is
            a : Character;
        begin
            CLS;
            PRINTING := True;
            Get(a);
            PRINTING := False;
            CLS;

        end showAllLogs;

        procedure showLogsForTrain (no: in Integer) is
            cursor : model.StrVectors.Cursor;
            size : Natural;
            keyL : keyListener;
        begin
            
            NOKEY := True;
            while NOKEY loop
                CLS;
                size := Natural(model.StrVectors.Length(trains(no).logs)) - 1;
                for I in 1..size loop
                    Put_Line(trains(no).logs(I));
                end loop;

                delay 0.1;
            end loop;

        end showLogsForTrain;

        procedure showJobsLogs is
            pL : PJobStruct;
            temp, c : Integer;
            keyL : keyListener;
        begin
            c := 0;
            CLS;
            NOKEY := True;
            while NOKEY loop
                CLS;
                c := c + 1;
                for I in 1..Integer(jobs.Length) loop
                    pL := jobs(I);
                    --if pL.finished = false then 
                        Put_Line("Job " & Integer'Image(I) & " station " & Integer'Image(pl.station));
                        temp := Integer(jobs(I).logs.Length);
                        Put_Line(jobs(I).logs(temp));
                        for J in 1..Integer(jobs(I).groups.Length) loop
                            Put_Line("\tGroup " & Integer'Image(J) & " : " & jobs(I).groups(J));
                        end loop;
                    --end if; 
                end loop;
                Put_Line(Integer'Image(c));
                delay 0.1;
            end loop;

        end showJobsLogs;

        procedure startUI is
            option : Character;
            choice : Integer;
            running : Boolean := True;
        begin
            delay 1.0;
            while running loop
                CLS;
                Put_Line("---Menu---");
                Put_Line("[1] Zdarzenia dla wszystkich pociagów");
                Put_Line("[2] Zdarzenia dla pociągu nr");
                Put_Line("[3] Wszystkie zdarzenia");
                Put_Line("[4] Prace");


                Get(option);
                Put_Line("Wybrana opcja " & option);

                if option = '1' then
                    --showLogsForTrains;
                    null;
                elsif option = '2' then
                    Get(choice);
                    showLogsForTrain(choice);
                elsif option = '3' then
                    showAllLogs;
                elsif option = '4' then
                    showJobsLogs;
                elsif option = 'q' then
                    running := false;
                end if;

            end loop;
        end startUI;

end UI;
