
package UI is

    NOKEY : Boolean := True;

    procedure showLogsForTrains;

    procedure showLogsForTrain (no: in Integer);

    procedure showAllLogs;

    procedure startUI;

    procedure CLS;

    task type keyListener is
    end keyListener;

end UI;
