with model; use model;
with Master; use Master;
with Ada.Numerics.discrete_Random;
with Ada.Integer_Text_Io; use Ada.Integer_Text_Io;
with Ada.Text_Io; use Ada.Text_Io;
with Ada.Containers.Vectors; use Ada.Containers;

package body JobsGenerator is
    task body JobMaster is
        package Rand_Int is new Ada.Numerics.Discrete_Random(Size);

        generator : Rand_Int.Generator;
        function randInt (max : in Size) return Size is
        begin
            return Rand_Int.Random(generator) mod max + 1;
        end randInt;



        task type JobTask is
            entry setGroups (
                nooGroups : in Integer;
                jobLogStruct : in PJobStruct
            );
            entry report (
                nr : in Integer
            );
            entry reportOff (
                nr : in Integer
            );
        end JobTask;
        task body JobTask is
            numberOfGroups : Integer;
            logStruct : PJobStruct;
        begin
            Put_Line("New Job started");
            accept setGroups (
                nooGroups : in Integer;
                jobLogStruct : in PJobStruct
            ) do
                numberOfGroups := nooGroups;
                logStruct := jobLogStruct;
            end setGroups;

            Put_Line("Job " & Integer'Image(numberOfGroups));

            logStruct.logs.Append("Waiting for groups");
            Put_Line(logStruct.logs.Last_Element);

            for I in 1..numberOfGroups loop
                accept report (
                    nr : in Integer
                ) do
                    null;
                end report;
            end loop;

            logStruct.logs.Append("Working...");

            Put_Line(logStruct.logs.Last_Element);
            delay 10.0;

            logStruct.logs.Append("Work finished");

            Put_Line(logStruct.logs.Last_Element);
            for I in 1..numberOfGroups loop
                accept reportOff (
                    nr : in Integer
                 ) do
                    null;
                end reportOff;
            end loop;

            logStruct.logs.Append("All done");

            Put_Line(logStruct.logs.Last_Element);
            delay 2.0;
            logStruct.finished := true;
        end JobTask;

        procedure GoByTrain ( source, destination, logID : in Integer; logStruct : in PJobStruct) is
            train1, train2, layover : Integer;
            temp, temp1, temp2, K, I : Integer := -1;
            maxId : Natural;
        begin
            Put_Line(Integer'Image(I));
            I := I + 1;
            for trainID in 1..Integer(stations(source).trains.Length) loop
                Put_Line("a1");
                for c in trains(trainId).stations.Iterate loop
                    temp2 := IntVectors.Element(c);
                    Put_Line("a2 " & Integer'Image(temp2));
                    if temp2 = destination then
                        Put_Line("b1");
                        train1 := trainID;
                        Put_Line("b2");
                        exit;
                    end if;
                    Put_Line("a3");
                end loop;
            end loop;

            Put_Line(Integer'Image(I) & " >>>" & Integer'Image(train1));
            I := I + 1;

            if train1 < 0 then
                for train1ID in 1..Integer(stations(source).trains.Length) loop
                    for station1ID in 1..Integer(trains(train1ID).stations.Length) loop
                        K := trains(train1ID).stations(station1ID);
                        for train2ID in 1..Integer(stations(K).trains.Length) loop
                            for station2ID in 1..Integer(trains(train2ID).stations.Length) loop
                                if station2ID = destination then
                                    train1 := train1ID;
                                    layover := K;
                                    train2 := train2ID;
                                end if;
                            end loop;
                        end loop;
                    end loop;
                end loop;
            end if;
            
            Put_Line(Integer'Image(I));
            I := I + 1;
            Put_Line("Test1");
            --logStruct.groups.Replace_Element(logID, "Waiting for train " & Integer'Image(train1) & " on station " & Integer'Image(source));
            Put_Line("Test2");
            loop
                temp := trains(train1).lastStation;
                exit when temp = source;
                delay 0.01;
            end loop;
            --logStruct.groups(logID) := "Going by train " & Integer'Image(train1);

            Put_Line(Integer'Image(I) & "A1");
            I := I + 1;

            
            if layover = -1 then
                loop
                    temp := trains(train1).lastStation;
                    exit when temp = destination;
                    delay 0.01;
                end loop;
            else

            Put_Line(Integer'Image(I) & "A2");
            I := I + 1;

                loop
                    temp := trains(train1).lastStation;
                    exit when temp = layover;
                    delay 0.01;
                end loop;

            Put_Line(Integer'Image(I) & "A3");
            I := I + 1;


                --logStruct.groups(logID) := "Waiting for train " & Integer'Image(train2) & " on station " & Integer'Image(layover);
                loop
                    temp := trains(train2).lastStation;
                    exit when temp = layover;
                    delay 0.01;
                end loop;
                --logStruct.groups(logID) := "Going by train " & Integer'Image(train2);
                loop
                    temp := trains(train2).lastStation;
                    exit when temp = destination;
                    delay 0.01;
                end loop;
            end if;
            --logStruct.groups(logID) := "Arrived to station " & Integer'Image(destination);
        end GoByTrain;

        type PJobTask is access JobTask;
        procedure FreeJobTask is new Ada.Unchecked_Deallocation(JobTask, PJobTask);

        task type GroupTask is
            entry setJobTask (
                jobTaskMaster : in PJobTask;
                source : in Integer;
                destination : in Integer;
                id : in Integer;
                jobLogStruct : in PJobStruct
            );
        end GroupTask;
        task body GroupTask is
            jobTaskM : PJobTask;
            s, d, logID : Integer;
            logStruct : PJobStruct;
        begin
            Put_Line("New group started");
            accept setJobTask (
                jobTaskMaster : in PJobTask;
                source : in Integer;
                destination : in Integer;
                id : in Integer;
                jobLogStruct : in PJobStruct
            ) do
                jobTaskM := jobTaskMaster;
                s := source;
                d := destination;
                logID := id;
                logStruct := jobLogStruct;
            end setJobTask;

            Put_Line("Group " & Integer'Image(s) & " " & Integer'Image(d));

            Put_Line("AAA");
            --logStruct.groups(logID) := "Calculating route";
            Put_Line("BBB");
            GoByTrain(platforms(s).station, d, logID, logStruct);
            --go from source to destination
            Put_Line("CCC");
            --logStruct.groups(logID) := "Arrived";
            Put_Line("DDD");
            jobTaskM.report(s);
            --logStruct.groups(logID) := "Working...";
            jobTaskM.reportOff(s);
            Put_Line("EEE");
            --logStruct.groups(logID) := "Going home";
            Put_Line("FFFF");
            GoByTrain(d, platforms(s).station, logID, logStruct);
            --go from dest to source

        end GroupTask;

        temp, temp1: Size;
        groups : Integer;
        tmpJobTask : PJobTask;
        jobLogStruct : PJobStruct;
    begin
        loop
            --temp := randInt(10);
            temp := 9;
            if temp > 7 then
                temp := randInt(nooStations);
                groups := 0;
                tmpJobTask := new JobTask;
                jobLogStruct := new JobStruct;
                jobLogStruct.finished := false;
                jobLogStruct.station := temp;
                jobLogStruct.logs.Append("New Job");
                for I in 1..nooPlatforms loop
                    temp1 := randInt(10);
                    if temp1 > 0 then
                        groups := groups + 1;
                        jobLogStruct.groups.Append("Group " & Integer'Image(I) & " started");
                        declare
                            groupT : GroupTask;
                        begin
                            groupT.setJobTask(tmpJobTask, I, temp, groups, jobLogStruct);
                        end;
                    end if;
                end loop;
                if groups > 0 then
                    jobs.Append(jobLogStruct);
                    tmpJobTask.setGroups(groups, jobLogStruct);
                end if;
            end if;

            delay 15.0;

        end loop;

    end JobMaster;

end JobsGenerator;