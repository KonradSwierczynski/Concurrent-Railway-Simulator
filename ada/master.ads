with model; use model;
with Ada.Unchecked_Deallocation;



package Master is

    procedure Main;

     protected type taskSwitch(ps: model.PSwitch) is
            entry Lock(id : in Integer; s : out model.PSwitch);
            entry Unlock(id : in Integer);
            private
            Empty : Boolean := True;
            Status : Integer := -1;
            train : model.PTrain;
    end taskSwitch;

    protected type taskLine(pl : model.PLine) is
        entry Lock(id : in Integer; l : out model.PLine);
        entry Unlock(id : in Integer);
        private
        Empty : Boolean := True;
        Status : Integer := -1;
        train : model.PTrain;
    end taskLine;

    protected type taskPlatform(pp :model.PPlatform) is
        entry Lock(id : in Integer; p : out model.PPlatform);
        entry Unlock(id : in Integer);
        private
        Empty : Boolean := True;
        Status : Integer := -1;
        train : model.PTrain;
    end taskPlatform;

    EMPTYI : constant Integer := -1;
    MAXSIZE : constant Integer := 1000;
    subtype SIZE is Integer range 1..MAXSIZE;

    PRINTING : Boolean := False;

    type PtaskSwitch is access taskSwitch;
    type PtaskLine is access taskLine;
    type PtaskPlatform is access taskPlatform;

    procedure FreeTS is new Ada.Unchecked_Deallocation(taskSwitch, PtaskSwitch);
    procedure FreeTL is new Ada.Unchecked_Deallocation(taskLine, PtaskLine);
    procedure FreeTP is new Ada.Unchecked_Deallocation(taskPlatform, PtaskPlatform);

    tswitches : array(SIZE) of PtaskSwitch;
    tlines: array(SIZE) of PtaskLine;
    tplatforms : array(SIZE) of PtaskPlatform;

    matrix : array(SIZE, SIZE) of Integer;

    nooSwitches, nooLines, nooPlatforms, nooStations, nooTrains, secPerHour, repairTime : Integer;

    switches : array(SIZE) of model.PSwitch;
    lines : array(SIZE) of model.PLine;
    platforms : array(SIZE) of model.PPlatform;
    trains : array(SIZE) of model.PTrain;
    stations : array(SIZE) of model.PStation;
    jobs : JobVectors.Vector;

end Master;
