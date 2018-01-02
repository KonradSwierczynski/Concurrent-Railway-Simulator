with Ada.Unchecked_Deallocation;
with Ada.Integer_Text_Io; use Ada.Integer_Text_Io;
with Ada.Text_Io; use Ada.Text_Io;
with Ada.Strings.Unbounded;
with model; use model;
with Ada.Containers.Indefinite_Vectors; use Ada.Containers;
with Reading; use Reading;
with UI; use UI;
with FailuresGenerator; use FailuresGenerator;
with JobsGenerator; use JobsGenerator;


-- author: Konrad Świerczyński

package body Master is

    protected body taskSwitch is

        entry Lock(id : in Integer; s : out model.PSwitch) when Empty is
        begin
            Status := id;
            Empty := False;

            if PRINTING then
                Put_Line("Train " & Integer'Image(id) & " => Switch " & Integer'Image(ps.id));
            end if;
            if id /= 999 then
                train := trains(id);
                train.logs.Append("Train " & Integer'Image(id) & " => Switch " & Integer'Image(ps.id));
                train.logsSize := train.logsSize + 1;
            end if;
            s := ps;
        end Lock;

        entry Unlock(id : in Integer) when not Empty is
        begin
            Status := EMPTYI;
            Empty := True;
        end Unlock;

    end taskSwitch;
    
    protected body taskLine is

    entry Lock(id : in Integer; l : out model.PLine) when Empty is
    begin
        Status := id;
        Empty := False;
        if PRINTING then
            Put_Line("Train " & Integer'Image(id) & " => Line " & Integer'Image(pl.id));
        end if;
        if id /= 999 then
            train := trains(id);
            train.logs.Append("Train " & Integer'Image(id) & " => Line " & Integer'Image(pl.id));
            train.logsSize := train.logsSize + 1;
        end if;
            l := pl;
        end Lock;

        entry Unlock(id : in Integer) when not Empty is
        begin
            Status := EMPTYI;
            Empty := True;
        end Unlock;

    end taskLine;

    protected body taskPlatform is

        entry Lock(id : in Integer; p : out model.PPlatform) when Empty is
begin
            Status := id;
            Empty := False;
            if PRINTING then
                Put_Line("Train " & Integer'Image(id) & " => Platform " & Integer'Image(pp.id));
            end if;
            if id /= 999 then
                train := trains(id);
                train.logs.Append("Train " & Integer'Image(id) & " => Platform " & Integer'Image(pp.id));
                train.logsSize := train.logsSize + 1;
            end if;
                p := pp;
        end Lock;

        entry Unlock(id : in Integer) when not Empty is
        begin
            Status := EMPTYI;
            Empty := True;
        end Unlock;

    end taskPlatform;

    procedure Main is
        
        task type startTrain(t : model.PTrain) is
        end startTrain;
        task body startTrain is
            ps : model.PSwitch;
            pl : model.PLine;
            pp : model.PPlatform;
            pts : PtaskSwitch;
            ptl : PtaskLine;
            ptp : PtaskPlatform;
            railId, junctionId, speed : Integer;
        begin
            Put_Line("Train " & Integer'Image(t.id) & " started");
            t.position := 1;
            railId := t.route(t.position);

            if railId > nooLines then
                ptp := tplatforms(railId - noolines);
                ptp.Lock(t.id, pp);
                t.lastStation := platforms(railId - nooLines).station;
                delay Duration(Float(pp.minUsageTime) / Float(60) * Float(secPerHour));
            else
                ptl := tlines(railId);
                ptl.Lock(t.id, pl);
                if t.maxSpeed > pl.maxSpeed then
                    speed := pl.maxSpeed;
                else
                    speed := t.maxSpeed;
                end if;

                delay Duration((Float(pl.lenght) / Float(speed)) * Float(secPerHour));
            end if;

            loop
                
                junctionId := t.junctions(t.position);

                pts := tswitches(junctionId);
                pts.Lock(t.id, ps);

                if railId > nooLines then
                    ptp.Unlock(t.id);
                else
                    ptl.Unlock(t.id);
                end if;

                delay Duration(Float(ps.minUsageTime) / Float(60) * Float(secPerHour));
                
                t.position := t.position + 1;
                if t.position > t.routeSize then
                    t.position := 1;
                end if;

                railId := t.route(t.position);

                if railId > nooLines then
                    ptp := tplatforms(railId - noolines);
                    ptp.Lock(t.id, pp);
                    t.lastStation := platforms(railId - nooLines).station;
                    pts.Unlock(t.id);
                    delay Duration(Float(pp.minUsageTime) / Float(60) * Float(secPerHour));
                else
                    ptl := tlines(railId);
                    ptl.Lock(t.id, pl);
                    if t.maxSpeed > pl.maxSpeed then
                        speed := pl.maxSpeed;
                    else
                        speed := t.maxSpeed;
                    end if;
                    pts.Unlock(t.id);
                    delay Duration(Float(pl.lenght) / Float(speed) * Float(secPerHour));
                end if;


            end loop;
        end startTrain;

        type PtaskSTrain is access startTrain;
        procedure FreeTT is new Ada.Unchecked_Deallocation(startTrain, PtaskSTrain);
        rVehicle : PrepairVehicle;
        jGenerator : PJobMaster;
        procedure FreeTR is new Ada.Unchecked_Deallocation(repairVehicle, PrepairVehicle);
        ttrains : array(SIZE) of PtaskSTrain;
                
        iter : Integer := 1;

        procedure freeResources is
        begin
            for I in 1..nooTrains loop
                FreeTT(ttrains(I));
                model.FreeT(trains(I));
            end loop;

            for I in 1..nooSwitches loop
                FreeTS(tswitches(I));
                model.FreeS(switches(I));
            end loop;

            for I in 1..nooLines loop
                FreeTL(tlines(I));
                model.FreeL(lines(I));
            end loop;

            for I in 1..nooPlatforms loop
                FreeTP(tplatforms(I));
                model.FreeP(platforms(I));
            end loop;

            for I in 1..nooStations loop
                model.FreeSt(stations(I));
            end loop;

            Put_Line("Deallocatin repairVehicle");

            FreeTR(rVehicle);

            Put_Line("Deallocate repairVehicle");

        end freeResources;


    begin
 
        readData;

        Put_Line("Preparation finished");
        PRINTING := False;

        loop
            exit when iter > nooTrains;

            declare
            begin
                ttrains(iter) := new startTrain(trains(iter));
            exception
                when Tasking_Error =>
                    Put_Line("Tasking error while allocating new task nr: " & Integer'Image(iter));
                    iter := iter - 1;
                    exit;
            end;
            iter := iter + 1;
        end loop;

        --rVehicle := new repairVehicle;
        jGenerator := new JobMaster;
        --delay 100.0;
        startUI;

        freeResources; 
    end Main;

end Master;
