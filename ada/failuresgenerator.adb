with model; use model;
with Master; use Master;
with Ada.Numerics.discrete_Random;
with Ada.Integer_Text_Io; use Ada.Integer_Text_Io;
with Ada.Text_Io; use Ada.Text_Io;
with Ada.Containers.Vectors; use Ada.Containers;


package body FailuresGenerator is

    task body repairVehicle is

        package Rand_Int is new Ada.Numerics.Discrete_Random(Size);
        package SizeVector is new Vectors(Natural, Integer);

        generator : Rand_Int.Generator;

        function randInt (max : in Size) return Size is
        begin
            return Rand_Int.Random(generator) mod max + 1;
        end randInt;


        task type generateFailures is
            entry Recive (
                    isTrain:    out boolean;
                    trainId:    out Size;
                    elementId:     out Size
                );
        end generateFailures;
        task body generateFailures is
            t   :   boolean := false;
            toRepair : boolean := false;
            train : Size := 1;
            element : Size := 1;
            temp : Size;
        begin

            loop
                temp := randInt(1);
                if temp = 1 then
                    toRepair := true;
                    t := false;
                    temp := randInt(nooLines + nooPlatforms);
                else
                    toRepair := true;
                    t := true;
                    temp := randInt(nooTrains);
                end if;

                if toRepair then
                    Put_Line("RepairMessage -> trainId" & Integer'Image(train) &
                                    " elemId " & Integer'Image(element));
                    accept Recive (
                            isTrain: out boolean;
                            trainId: out Size;
                            elementId:  out Size
                        ) do
                        isTrain := t;
                        trainId := train;
                        elementId := element;
                    end Recive;

                    toRepair := false;
                end if;

                delay 5.0;

            end loop;
        end generateFailures;

        freeLines :     SizeVector.Vector;
        freeSwitches :  SizeVector.Vector;
        
        procedure printFreeElements is
            element : SIZE;
        begin
            Put_Line("Free switches:");
            for c in freeSwitches.Iterate loop
                element := SizeVector.Element(c);
                Put_Line(Integer'Image(element) & " ");
            end loop;
            Put_Line("Free lines:");
            for c in freeLines.Iterate loop
                Put_Line(Integer'Image(SizeVector.Element(c)));
            end loop;
            New_Line(1);
        end printFreeElements;



        procedure getFreeElements is
            id : Integer := 999;
            ps : PSwitch;
            pl : PLine;
            pp : PPlatform;
        begin
            for J in 1..nooSwitches loop    
                select
                    tswitches(J).Lock(id, ps);
                    freeSwitches.Append(J);
                else
                    null;    
                end select;
            end loop;
            for J in 1..nooLines loop    
                select
                    tlines(J).Lock(id, pl);
                    freeLines.Append(J);
                else
                    null;
                end select;
            end loop;
            for J in 1..nooPlatforms loop    
                select
                    tplatforms(J).Lock(id, pp);
                    freeLines.Append(J);
                else
                    null;    
                end select;
            end loop;
        end getFreeElements;
                
        d :             array(SIZE) of Integer;
        prev :          array(SIZE) of Size;

        START : SIZE := MAXSIZE - 2;

        route :         SizeVector.Vector;
        routeSwitches : SizeVector.Vector;

        function isIn(t : Integer; val : SIZE) return boolean is
        begin
            if t = 1 then   --switch
                for c in freeSwitches.Iterate loop
                    if val = SizeVector.Element(c) then
                        return true;
                    end if;
                end loop;
                return false;
            elsif t = 2 then    --line or platform
                for c in freeLines.Iterate loop
                    Put_Line(">> " & Integer'Image(SizeVector.Element(c)));
                    if val = SizeVector.Element(c) then
                        Put_Line("IS IN VECTOR");
                        return true;
                    end if;
                end loop;
                return false;
            elsif t = 3 then    --route lines
                for c in route.Iterate loop
                    Put_Line(">>> " & Integer'Image(SizeVector.Element(c)));
                    if val = SizeVector.Element(c) then
                       Put_Line("IS IN VECTOR");
                       return true;
                    end if;
                end loop;
                return false;
            elsif t = 4 then    --route switches
                for c in routeSwitches.Iterate loop
                    if val = SizeVector.Element(c) then
                        return true;
                    end if;
                end loop;
                return false;
            end if;
            return false;

        end isIn;

        procedure dijkstra (source : Size) is
            I : Size := 1;
            J : Size := 1;
            u : Size;
            Q : SizeVector.Vector;
        begin
            I := 1;
            for k in d'range loop
                d(k) := MAXSIZE;
                prev(k) := MAXSIZE;
            end loop;
            
            if isIn(1, source) then
                for k in 1..nooLines + nooPlatforms loop
                    for l in 1..nooLines + nooPlatforms loop
                        if matrix(k, l) = source then
                            if k /= l then
                                if isIn(2, k) then
                                    d(k) := 0;
                                    prev(k) := START;
                                    Q.Append(k);
                                end if;
                                if isIn(2, l) then
                                    d(l) := 0;
                                    prev(l) := START;
                                    Q.Append(l);
                                end if;
                            end if;
                        end if;
                    end loop;
                end loop;
            end if;

            while Q.Length > 0 loop

                u := Q.First_Element;
                Q.Delete_First;
                I := 1;
                while I <= nooLines + nooPlatforms loop
                    if u /= I and matrix(u, I) /= -1 then
                        if isIn(1, matrix(u, I)) then
                            if isIn(2, I) then
                                if d(I) > d(u) + 1 then
                                    d(I) := d(u) + 1;
                                    prev(I) := u;
                                    Q.Append(I);
                                end if;
                            end if;
                        end if;
                    end if;
                    I := I + 1;
                end loop;
            end loop;
        end dijkstra;

        procedure getPath (
                    isTrain:    in boolean;
                    trainId:    in Size;
                    elementId:  in Size;
                    source:     in Size
                ) is
            dest : Size;
            I : Size;
            min : Integer;
            newDest : Size;
        begin
            if isTrain then
                newDest := trains(trainId).route(trains(trainId).position);
                min := d(newDest);
                dest := newDest;
                for k in 1..nooLines + nooPlatforms loop
                        if matrix(k, newDest) /= -1 then
                            if min > d(k) then
                                if isIn(2, k) then
                                    min := d(k);
                                    dest := k;
                                end if;
                            end if;
                        end if;
                end loop;
            else
                dest := elementId;
            end if;

            if not isIn(2, dest) then
                SizeVector.Clear(route);
                SizeVector.Clear(routeSwitches);
            else
                
                I := dest;
                Put_Line("Route");
                while I /= START loop
                    Put_Line(Integer'Image(I) & " " & Integer'Image(prev(I)) & " " & Integer'Image(matrix(I, prev(I))));
                    route.Append(I);
                    if prev(I) = START then
                        routeSwitches.Prepend(source);
                    else
                        routeSwitches.Prepend(matrix(I, prev(I)));          
                    end if;
                    I := prev(I);
                end loop;
            end if;
        end getPath;

        procedure freeUnused is
            id : SIZE;
        begin
            for c in freeLines.Iterate loop
                id := SizeVector.Element(c);
                if not isIn(3, id) then
                    if id > nooLines then
                        tplatforms(id).Unlock(START);
                    else
                        tlines(id).Unlock(START);
                    end if;
                end if;
            end loop;
            SizeVector.Clear(freeLines);
            for c in freeSwitches.Iterate loop
                if not isIn(4, SizeVector.Element(c)) then
                    tswitches(SizeVector.Element(c)).Unlock(START);
                end if;
            end loop;
            SizeVector.Clear(freeSwitches);
        end freeUnused;

        procedure clearTabs is
        begin
            SizeVector.Clear(freeLines);
            SizeVector.Clear(freeSwitches);
            SizeVector.Clear(routeSwitches);
            SizeVector.Clear(route);

        end clearTabs;

        procedure goAndRepair is
            railId, switchId : SIZE;
            
        begin
            
             --for c in routeSwitches.Iterate loop
             --   Put_Line("Start... ");
             --   switchId := SizeVector.Element(c);
             --  Put_Line("Switch: " & Integer'Image(switchId) & " index " & Integer'Image(SizeVector.To_Index(c)));
             --   railId := SizeVector.Element(route, SizeVector.To_Index(c));
             --   
             --   Put_Line("Repair vehicle => switch " & Integer'Image(switchId));
             --
             --  delay Duration(Float(switches(switchId).minUsageTime) / Float(60) * Float(secPerHour));
             --   
             --   Put_Line("Repair vehicle => line " & Integer'Image(railId));
             --
             --   if railId > nooLines then
             --       delay Duration(Float(platforms(railId).minUsageTime) / Float(60) * Float(secPerHour));
             --   else
             --       delay Duration(Float(lines(railId).lenght) / Float(lines(railId).maxSpeed) * Float(secPerHour));
             --   end if;
             --
             --end loop;          
            for i in 0..Natural(route.Length) - 1 loop
                Put_Line("Start... " & Integer'Image(Integer(i)));
                switchId := SizeVector.Element(routeSwitches, Natural(i));
                railId := SizeVector.Element(route, Natural(i));
                
                Put_Line("Repair vehicle => switch " & Integer'Image(switchId));

                delay Duration(Float(switches(switchId).minUsageTime) / Float(60) * Float(secPerHour));
                
                Put_Line("Repair vehicle => line " & Integer'Image(railId));

                if railId > nooLines then
                    delay Duration(Float(platforms(railId).minUsageTime) / Float(60) * Float(secPerHour));
                else
                    delay Duration(Float(lines(railId).lenght) / Float(lines(railId).maxSpeed) * Float(secPerHour));
                end if;

            end loop;

            Put_Line("Repairing..");

            delay Duration(Float(repairTime) * Float(secPerHour));

            Put_Line("Repaired..");
            
            SizeVector.Reverse_Elements(route);
            SizeVector.Reverse_Elements(routeSwitches);
            Put_Line("Reversed");

            if railId > nooLines then
                Put("1");
                tplatforms(railId).Unlock(START);
                Put_Line("11");
            else
                Put("2 " & Integer'Image(railId));
                tlines(railId).Unlock(START);
                Put_Line("22");
            end if;
            
            Put_Line("Repair vehicle => switch " & Integer'Image(switchId));

            delay Duration(Float(switches(switchId).minUsageTime) / Float(60) * Float(secPerHour));

            tswitches(switchId).Unlock(START);
            Put_Line("Start new loop");
            for i in 1..Natural(route.Length) - 1 loop
                Put_Line("test");
                switchId := routeSwitches.Element(i);
                railId := route.Element(i);
                
                Put_Line("Repair vehicle => line " & Integer'Image(railId));

                if railId > nooLines then
                    delay Duration(Float(platforms(railId).minUsageTime) / Float(60) * Float(secPerHour));
                    tplatforms(railId).Unlock(START);
                else
                    delay Duration(Float(lines(railId).lenght) / Float(lines(railId).maxSpeed) * Float(secPerHour));
                    tlines(railId).Unlock(START);
                end if;
                
                Put_Line("Repair vehicle => switch " & Integer'Image(switchId));

                delay Duration(Float(switches(switchId).minUsageTime) / Float(60) * Float(secPerHour));
                tswitches(switchId).Unlock(START);
            end loop;

            SizeVector.Clear(route);
            SizeVector.Clear(routeSwitches);
        end goAndRepair;

        failureGen :    generateFailures;
        train :         boolean := false;
        trainId :       Size;
        elementId :     Size;
    begin
        Rand_Int.Reset(generator);
        Put_Line("Repair Vehicle started");
        loop
            PRINTING := True;

            Put_Line("Waiting for message");

            failureGen.Recive(train, trainId, elementId);

            if train then
                Put_Line("Train no " & Integer'Image(trainId) & " broken");
            else
                Put_Line("Line no " & Integer'Image(elementId) & " broken");
            end if;
            
            getFreeElements;

            printFreeElements;

            dijkstra(1);

            for i in 1..nooLines + nooPlatforms loop
                Put_Line(Integer'Image(i) & " " & Integer'Image(d(i)) & " " & Integer'Image(prev(i)));
            end loop;
            New_Line(1);

            Put_Line("Route counted");

            New_Line(1);

            getPath(train, trainId, elementId, 1);

            Put_Line("Path selected:");
            Put_Line(">>><<<<>>> " & Integer'Image(Integer(route.Length)));

            for c in route.Iterate loop
                Put_Line("line: " & Integer'Image(SizeVector.Element(c)));
            end loop;

            for c in routeSwitches.Iterate loop
                Put_Line("switch: " & Integer'Image(SizeVector.Element(c)));
            end loop;

            Put_Line("Free unused...");

            freeUnused;

            Put_Line("Freed unused");

            if Integer(route.Length) < 1 then
                Put_Line("Can not make route");
            else
                Put_Line("go and repair");
                
                goAndRepair;

                Put_Line("reaired");
                
                Put_Line("Back in home");
            end if;

            clearTabs;

        end loop;

    end repairVehicle;



end FailuresGenerator;
