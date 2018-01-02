with Ada.Strings.Unbounded;
with Ada.Containers.Indefinite_Vectors; use Ada.Containers;
with Ada.Unchecked_Deallocation;


package model is

    type IntArray is array(Integer range <>) of Integer;
    package StrVectors is new Indefinite_Vectors(Natural, String);
    package IntVectors is new Indefinite_Vectors(Natural, Integer);

    type Switch(minUsageTime : Integer) is record
        id : Integer := 0;
    end record;

    type Line(lenght, maxSpeed : Integer) is record
        id : Integer := 0;
    end record;

    type Platform(minUsageTime : Integer) is record
        id : Integer := 0;
        station : Integer := 0;
    end record;

    type Station is record
        id : Integer;
        trains : IntVectors.Vector;
    end record;

    type JobStruct is record
        finished : Boolean := false;
        logs : StrVectors.Vector;
        groups : StrVectors.Vector;
        station : Integer;
    end record;

    type Train(id, maxSpeed, maxCapacity, routeSize : Integer) is record
        route : IntArray(1..routeSize);
        junctions : IntArray(1..routeSize);
        logs : StrVectors.Vector;
        stations : IntVectors.Vector;
        logsSize : Integer := 0;
        position : Integer := 0;
        lastStation : Integer := 0;
    end record;

    type PSwitch is access Switch;
    type PLine is access Line;
    type PPlatform is access Platform;
    type PTrain is access Train;
    type PStation is access Station;
    type PJobStruct is access JobStruct;

    package JobVectors is new Indefinite_Vectors(Natural, PJobStruct);

    procedure FreeS is new Ada.Unchecked_Deallocation(Switch, PSwitch);
    procedure FreeL is new Ada.Unchecked_Deallocation(Line, PLine);
    procedure FreeP is new Ada.Unchecked_Deallocation(Platform, PPlatform);
    procedure FreeT is new Ada.Unchecked_Deallocation(Train, PTrain);
    procedure FreeSt is new Ada.Unchecked_Deallocation(Station, PStation);
    procedure FreeJS is new Ada.Unchecked_Deallocation(JobStruct, PJobStruct);

end model;
