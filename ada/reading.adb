with Ada.Integer_Text_Io; use Ada.Integer_Text_Io;
with Ada.Text_Io; use Ada.Text_Io;
with model; use model;
with Master; use Master;

package body Reading is

    procedure readData is
        I, K : SIZE := 1;
        temp, temp1, temp2, temp3 : Integer := 0;
        begin
            Get(secPerHour);
            Get(repairTime);
            Get(nooSwitches);
            Get(nooLines);
            Get(nooPlatforms);
            Get(nooStations);
            Get(nooTrains);

            Put_Line(Integer'Image(nooSwitches) & " " & Integer'Image(nooLines) & " " & Integer'Image(nooPlatforms) & " " & Integer'Image(nooTrains) );
            
            loop
                exit when I > nooSwitches;
                declare
                begin
                    Get(temp);
                    switches(I) := new model.Switch(temp);
                    switches(I).id := I;
                end;
                I := I + 1;
            end loop;

            Put_Line("Finished reading switches");

            I := 1;
            loop
                exit when I > nooLines;
                declare
                begin
                    Get(temp1);
                    Get(temp2);

                    lines(I) := new model.Line(temp1, temp2);
                    lines(I).id := I;
                end;
                I := I + 1;
            end loop;

            Put_Line("Finished reading lines");

            I := 1;
            loop
                exit when I > nooPlatforms;
                declare
                begin
                    Get(temp);
                    Get(temp1);

                    platforms(I) := new model.Platform(temp);
                    platforms(I).id := I;
                    platforms(I).station := temp1;
                end;
                I := I + 1;
            end loop;

            I := 1;
            loop
                exit when I > nooStations;
                declare
                begin
                    stations(I) := new model.Station;
                    stations(I).id := I;
                end;
                I := I + 1;
            end loop;

            Put_Line("Finished reading platforms");

            I := 1;
            loop
                exit when I > nooTrains;
                declare
                begin
                    Get(temp1);
                    Get(temp2);
                    Get(temp3);

                    Put_Line(Integer'Image(temp1) & " " & Integer'Image(temp2) & " " & Integer'Image(temp3) & Integer'Image(I));
            


                    trains(I) := new model.Train(I, temp1, temp2, temp3);
                    K := 1;
                    loop
                        exit when K > temp3;
                        declare
                        begin
                            Get(temp1);
                            Get(temp2);
                            trains(I).route(K) := temp1;
                            if temp1 > nooLines then
                                --trains(I).stations.Append(platforms(temp1 - nooLines).station);
                                --stations(temp1 - nooLines).trains.Append(I);
                                null;
                            end if;
                            trains(I).junctions(K) := temp2;
                    
                            Put_Line(Integer'Image(temp1) & " " & Integer'Image(temp2) & " " & Integer'Image(temp3) & Integer'Image(I) & Integer'Image(K));

                        end;

                        K := K + 1;
                    end loop;

                end;
                I := I + 1;
            end loop;

            I := 1;
            K := 1;

            loop
                exit when I > nooLines + nooPlatforms;
                loop
                    exit when K > nooLines + nooPlatforms;
                    Get(temp);
                    matrix(I, K) := temp;
                    K := K + 1;
                end loop;
                I := I + 1;
                K := 1;
            end loop;

            Put_Line("Reading finished");

            I := 1;
            loop
                exit when I > nooSwitches;
                declare
                begin
                    tswitches(I) := new taskSwitch(switches(I));
                end;
                I := I + 1;
            end loop;

            I := 1;
            loop
                exit when I > nooLines;
                declare
                begin
                    tlines(I) := new taskLine(lines(I));
                end;
                I := I + 1;
            end loop;

            I := 1;
            loop
                exit when I > nooPlatforms;
                declare
                begin
                    tplatforms(I) := new taskPlatform(platforms(I));
                end;
                I := I + 1;
            end loop;

        end readData;



end Reading;
