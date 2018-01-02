with Ada.Unchecked_Deallocation;

package FailuresGenerator is

    task type repairVehicle is
    end repairVehicle;

    RepairVehicleId : Integer := -1;

    type PrepairVehicle is access repairVehicle;

end FailuresGenerator;
