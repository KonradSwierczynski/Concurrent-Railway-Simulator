package main

import (
	"sync"
)

var (
	SWITCHTYPE    = 0
	LINETYPE      = 1
	PLATFORMTYPE  = 2
	TRAINTYPE     = 3
	REPAIRVEHICLE = 4
)

type Log struct {
	trainId int32
	typeId  int //0 - switch, 1 - line 2 - platform
	value   int32
}

type Message struct {
	id       int32
	response chan int32
}

type RepairMessage struct {
	id      int32
	element int
}

type WorkMessage struct {
	id       int
	response chan int
}

type Train struct {
	id          int32
	maxSpeed    int
	maxCapacity int
	route       []int
	logs        []Log
	stations    []int
	status      int32
	listeners   []chan int
	position    int
	damaged     bool
}

type Job struct {
	finished bool
	logs     []string
	groups   []*Group
}

type Group struct {
	source   int
	quantity int
	log      string
}

type JobsMaster struct {
	jobs []Job
}

type RepairVehicle struct {
	messageChan chan RepairMessage
	maxSpeed    int
	route       []int
	logs        []string
	status      int32
	position    int
	waitingLine int
}

type Line struct {
	c        chan Message
	mu       sync.Mutex
	lenght   int
	maxSpeed int
	status   int32
	id       int32
	damaged  bool
}

type Platform struct {
	c          chan Message
	mu         sync.Mutex
	minLayTime int
	status     int32
	damaged    bool
	station    int
	workers    int

	id int32
}

type Switch struct {
	c            chan Message
	mu           sync.Mutex
	minUsageTime int
	status       int32
	damaged      bool

	edges []int32
	id    int32
}
