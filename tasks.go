package main

import (
	"fmt"
	"math/rand"
	"strconv"
	"time"
)

var (
	fresh    int
	failures []RepairMessage
)

func listenOnTrain(train int, listenerChan chan int) {
	trains[train].listeners = append(trains[train].listeners, listenerChan)
}

func unlistenOnTrain(train int, listenerChan chan int) {
	for i, chanToTest := range trains[train].listeners {
		if listenerChan == chanToTest {
			trains[train].listeners = append(trains[train].listeners[:i], trains[train].listeners[i+1:]...)
			break
		}
	}
}

func getPath(sourceStation, destinationStation int) (int, int, int) {
	trainOne := -1
	trainTwo := -1
	layover := -1
	for _, trainID := range stations[sourceStation] {
		for _, stationID := range trains[trainID].stations {
			if stationID == destinationStation {
				trainOne = trainID
				return trainOne, layover, trainOne
			}
		}
	}

	if trainOne == -1 {
		for _, train1ID := range stations[sourceStation] {
			for _, station1ID := range trains[train1ID].stations {
				for _, train2ID := range stations[station1ID] {
					for _, station2ID := range trains[train2ID].stations {
						if station2ID == destinationStation {
							trainOne = train1ID
							layover = station1ID
							trainTwo = train2ID
							return trainOne, layover, trainTwo
						}
					}
				}
			}
		}
	}

	return trainOne, layover, trainTwo
}

func takeTrain(trainID, sourceStation, destinationStation int, group *Group) {
	listenerChan := make(chan int, 4)
	listenOnTrain(trainID, listenerChan)
	group.log = "Waiting for train " + strconv.Itoa(trainID) + " at station " + strconv.Itoa(sourceStation)

	for true {
		stationID := <-listenerChan
		if stationID == sourceStation {
			group.log = "Going by train " + strconv.Itoa(trainID)
			break
		}
	}

	for true {
		stationID := <-listenerChan
		if stationID == destinationStation {
			group.log = "Arrived to station " + strconv.Itoa(destinationStation)
			break
		}
	}

	unlistenOnTrain(trainID, listenerChan)
}

func travelByTrain(sourceStation, destinationStation, id, quantity int, group *Group) bool {
	train1, layover, train2 := getPath(sourceStation, destinationStation)

	if train1 == -1 {
		return false
		//Path does't exist
	}

	if layover == -1 {
		takeTrain(train1, sourceStation, destinationStation, group)
	} else {
		takeTrain(train1, sourceStation, destinationStation, group)
		takeTrain(train2, layover, destinationStation, group)
	}
	return true
}

func workersGroupMaster(platformNumber, quantity, destinationStation int, jobChan chan WorkMessage, jobIndex int) {
	platforms[platformNumber].workers -= quantity
	thisGroup := Group{source: platformNumber, quantity: quantity, log: "Group started"}
	master.jobs[jobIndex].groups = append(master.jobs[jobIndex].groups, &thisGroup)
	responseMessage := make(chan int)

	status := travelByTrain(platforms[platformNumber].station, destinationStation, platformNumber, quantity, &thisGroup)
	if !status {
		thisGroup.log = "No path to destination"
		for _, train := range stations[platforms[platformNumber].station] {
			thisGroup.log += " " + strconv.Itoa(train)
			for _, stat := range trains[train].stations {
				thisGroup.log += " " + strconv.Itoa(stat)
			}
		}
		jobChan <- WorkMessage{id: platformNumber, response: responseMessage}
		<-responseMessage
		platforms[platformNumber].workers += quantity
		return
	}
	thisGroup.log = "Arrived to station"

	if printing {
		fmt.Println("Group from platform ", platformNumber, " reached destination ", destinationStation)
	}

	jobChan <- WorkMessage{id: platformNumber, response: responseMessage}

	<-responseMessage

	thisGroup.log = "Finished work"

	travelByTrain(destinationStation, platforms[platformNumber].station, platformNumber, quantity, &thisGroup)

	thisGroup.log = "Returned to base"
	jobChan <- WorkMessage{id: platformNumber, response: responseMessage}
	platforms[platformNumber].workers += quantity
}

func jobMaster(numberOfGroups int, reportChan chan WorkMessage, index int) {
	if numberOfGroups <= 0 {
		return
	}

	master.jobs[index].finished = false

	master.jobs[index].logs = append(master.jobs[index].logs, "Waiting for workers")

	messages := make([]WorkMessage, numberOfGroups)

	for i := 0; i < numberOfGroups; i++ {
		messages[i] = <-reportChan
		message := "Waiting for workers " + strconv.Itoa(i+1) + "/" + strconv.Itoa(numberOfGroups)
		master.jobs[index].logs = append(master.jobs[index].logs, message)
	}

	master.jobs[index].logs = append(master.jobs[index].logs, "Working...")

	timeToWait := time.Duration(jobOnStationDuration * secPerHour)
	time.Sleep(timeToWait * time.Second)

	for i := 0; i < numberOfGroups; i++ {
		messages[i].response <- 0
	}
	master.jobs[index].logs = append(master.jobs[index].logs, "Work done")

	for i := 0; i < numberOfGroups; i++ {
		messages[i] = <-reportChan
	}
	timeToShowMessage := time.Duration(2)
	time.Sleep(timeToShowMessage * time.Second)
	master.jobs[index].logs = append(master.jobs[index].logs, "Job finished...")
	master.jobs[index].finished = true
}

func jobForWorkersGenerator() {
	reliability := 0.75
	pWorkersNeeded := 0.7
	r := rand.New(rand.NewSource(14))

	for running {
		e := r.Float64()

		if e > reliability {
			element := r.Int()%int(numberOfPlatforms) + 1
			stationNumber := platforms[element].station
			if printing {
				fmt.Println("Job to do on station ", stationNumber)
			}

			numberOfGroups := 0
			jobChan := make(chan WorkMessage)

			jobNumber := len(master.jobs)
			newJob := Job{finished: true, logs: make([]string, 0), groups: make([]*Group, 0)}
			master.jobs = append(master.jobs, newJob)

			for i := 1; i <= int(numberOfPlatforms); i++ {
				p := r.Float64()
				if p < pWorkersNeeded {
					workersNeeded := r.Int() % 20
					if workersNeeded > platforms[i].workers {
						workersNeeded = platforms[i].workers
					}

					if workersNeeded > 0 {
						numberOfGroups++
						go workersGroupMaster(i, workersNeeded, stationNumber, jobChan, jobNumber)
						//go goTo stationNumber and work
					}
				}
			}
			go jobMaster(numberOfGroups, jobChan, jobNumber)
			// go waitForWorkersAndSendThemHomeAfterWork(numberOfGroups, chan messageNew)
		}

		timeToWait := time.Duration(1 * secPerHour)
		time.Sleep(timeToWait * time.Second)
	}
}

func generateFailures() {
	reliability := 0.95
	r := rand.New(rand.NewSource(99))
	for running {

		e := r.Float64()

		if e > reliability {
			element := r.Int() % 3
			number := 0
			var elementType int
			switch element {
			case 0: //switch will break
				number = r.Int() % int(numberOfSwitches)
				elementType = SWITCHTYPE
				switches[number+1].damaged = true
			case 1: //line will break
				number = r.Int() % int(numberOfLines)
				elementType = LINETYPE
				lines[number+1].damaged = true
			case 2: //train will break
				number = r.Int() % int(numberOfTrains)
				elementType = TRAINTYPE
				trains[number+1].damaged = true
			}

			if printing {
				switch element {
				case SWITCHTYPE: //switch will break
					fmt.Println("Switch ", number+1, " broken")
				case LINETYPE: //line will break
					fmt.Println("Line ", number+1, " broken")
				case TRAINTYPE: //train will break
					fmt.Println("Train ", number+1, " broken")
				}
			}

			message := RepairMessage{id: int32(number + 1), element: elementType}

			repairVehicle.messageChan <- message
			fresh = fresh + 1
			failures = append(failures, message)

		}

		timeToWait := time.Duration(1 * secPerHour)
		time.Sleep(timeToWait * time.Second)
	}
}

func intInSlice(a int, list []int) bool {
	for _, b := range list {
		if b == a {
			return true
		}
	}
	return false
}

func taskRepairVehicle() {
	go generateFailures()

	queueChan := make(chan RepairMessage, 100)
	waitingMessages := 0

	for running {
		repairVehicle.logs = append(repairVehicle.logs, "### RepairVehicle => waiting")
		var message RepairMessage
		if waitingMessages > 0 {
			message = <-queueChan
			waitingMessages--
		} else {
			message = <-repairVehicle.messageChan
		}
		id := message.id
		element := message.element

		repairVehicle.logs = append(repairVehicle.logs, "### RepairVehicle => recived message")

		//Dijkstra alghorit for shortest path

		freeSwitches := make([]int, 0)
		responseSwitches := make([]chan int32, 0)
		freeLines := make([]int, 0)
		responseLines := make([]chan int32, 0)
		freePlatforms := make([]int, 0)
		responsePlatforms := make([]chan int32, 0)

		route := make([]int, 0)
		routeSwitches := make([]int, 0)
		routePlatforms := make([]int, 0)

		d := make([]int, numberOfLines+numberOfPlatforms+1)
		prev := make([]int, numberOfLines+numberOfPlatforms+1)

		Q := make([]int, 0)

		for i := 0; i < int(numberOfLines+numberOfPlatforms+1); i++ {
			d[i] = 30000
			prev[i] = -1
		}

		d[0] = 0
		Q = append(Q, 0)

		for j, s := range switches {
			responseSwitches = append(responseSwitches, make(chan int32))
			select {
			case s.c <- Message{id: int32(REPAIRVEHICLE), response: responseSwitches[len(responseSwitches)-1]}:
				freeSwitches = append(freeSwitches, j)
			default:

			}
		}
		freeLines = append(freeLines, 0)
		for j, l := range lines {
			responseLines = append(responseLines, make(chan int32))
			select {
			case l.c <- Message{id: int32(REPAIRVEHICLE), response: responseLines[len(responseLines)-1]}:
				freeLines = append(freeLines, j)
			default:
			}
		}

		for j, p := range platforms {
			responsePlatforms = append(responsePlatforms, make(chan int32))
			select {
			case p.c <- Message{id: int32(REPAIRVEHICLE), response: responsePlatforms[len(responsePlatforms)-1]}:
				freePlatforms = append(freePlatforms, j)
			default:
			}
		}

		for len(Q) > 0 {
			u := Q[0]
			Q = Q[1:]
			for v, s := range junctions[u] {
				if v != u && len(s) > 0 && intInSlice(s[0], freeSwitches) {
					if v >= len(lines) {
						if !intInSlice(v-len(lines)+1, freePlatforms) {
							continue
						}
					} else {
						if !intInSlice(v, freeLines) {
							continue
						}
					}
					if u >= len(lines) {
						if d[v] > d[u]+platforms[u-len(lines)+1].minLayTime {
							d[v] = d[u] + platforms[u-len(lines)+1].minLayTime
							prev[v] = u
							Q = append(Q, v)
						}
					} else {
						if d[v] > d[u]+lines[u].lenght/repairVehicle.maxSpeed {
							d[v] = d[u] + lines[u].lenght/repairVehicle.maxSpeed
							prev[v] = u
							Q = append(Q, v)

						}
					}
				}
			}
		}

		lineId := -1

		switch element {
		case SWITCHTYPE: //switch will break
			min := 30000
			for _, l := range switches[int(id)].edges {
				if d[int(l)] < min {
					lineId = int(l)
				}
			}
		case LINETYPE: //line will break
			lineId = int(id)
		case TRAINTYPE: //train will break
			lineId = trains[int(id)].route[trains[int(id)].position]
		}

		canRepair := false

		if lineId < 0 || d[lineId] >= 30000 {
			fmt.Println("Can't repair now")
		} else {
			for lineId != 0 {
				route = append(route, lineId)
				routeSwitches = append(routeSwitches, junctions[lineId][prev[lineId]][0])
				lineId = prev[lineId]
			}
			canRepair = true
		}

		for _, s := range freeSwitches {
			if !intInSlice(s, routeSwitches) {
				responseSwitches[s] <- int32(REPAIRVEHICLE)
			}
		}

		freeLines = freeLines[1:] //delete line 0
		for _, l := range freeLines {
			if !intInSlice(l, route) {
				responseLines[l] <- int32(REPAIRVEHICLE)
			}
		}

		for _, p := range freePlatforms {
			if !intInSlice(p+len(lines)-1, route) {
				responsePlatforms[p] <- int32(REPAIRVEHICLE)
			}
		}

		if canRepair {
			for i := len(route) - 1; i >= 0; i-- {
				repairVehicle.logs = append(repairVehicle.logs, "### RepairVehicle => switch "+strconv.Itoa(routeSwitches[i]))
				s := switches[routeSwitches[i]]
				time.Sleep(time.Duration(s.minUsageTime/60.0*secPerHour) * time.Second)
				if route[i] >= len(lines) {
					repairVehicle.logs = append(repairVehicle.logs, "### RepairVehicle => platform "+strconv.Itoa(route[i]-len(lines)+1))
					p := platforms[route[i]-len(lines)+1]
					time.Sleep(time.Duration(p.minLayTime/60.0*secPerHour) * time.Second)
				} else {
					repairVehicle.logs = append(repairVehicle.logs, "### RepairVehicle => line "+strconv.Itoa(route[i]))
					l := lines[route[i]]
					var speed int
					if repairVehicle.maxSpeed <= l.maxSpeed {
						speed = repairVehicle.maxSpeed
					} else {
						speed = l.maxSpeed
					}
					timeToWait := time.Duration(l.lenght / speed * secPerHour)
					time.Sleep(timeToWait * time.Second)
				}
			}
			repairVehicle.logs = append(repairVehicle.logs, "### RepairVehicle => REPAIRING...")
			fmt.Println("Repaired!")
			time.Sleep(time.Duration(repairTime/60.0*secPerHour) * time.Second)
			switch element {
			case SWITCHTYPE: //switch will break
				switches[int(id)].damaged = false
			case LINETYPE: //line will break
				lines[int(id)].damaged = false
			case TRAINTYPE: //train will break
				trains[int(id)].damaged = false
			}
			if printing {
				switch element {
				case SWITCHTYPE: //switch will break
					fmt.Println("Switch ", id, " repaired")
				case LINETYPE: //line will break
					fmt.Println("Line ", id, " repaired")
				case TRAINTYPE: //train will break
					fmt.Println("Train ", id, " repaired")
				}
			}

			fresh = fresh - 1

			for i := 0; i < len(route); i++ {

				if route[i] >= len(lines) {
					repairVehicle.logs = append(repairVehicle.logs, "### RepairVehicle => platform "+strconv.Itoa(route[i]-len(lines)+1))

					p := platforms[route[i]-len(lines)+1]
					time.Sleep(time.Duration(p.minLayTime/60.0*secPerHour) * time.Second)
				} else {
					repairVehicle.logs = append(repairVehicle.logs, "### RepairVehicle => line "+strconv.Itoa(route[i]))
					l := lines[route[i]]
					var speed int
					if repairVehicle.maxSpeed <= l.maxSpeed {
						speed = repairVehicle.maxSpeed
					} else {
						speed = l.maxSpeed
					}
					timeToWait := time.Duration(l.lenght / speed * secPerHour)
					time.Sleep(timeToWait * time.Second)
				}
				repairVehicle.logs = append(repairVehicle.logs, "### RepairVehicle => switch "+strconv.Itoa(routeSwitches[i]))
				s := switches[routeSwitches[i]]
				time.Sleep(time.Duration(s.minUsageTime/60.0*secPerHour) * time.Second)
			}

		} else {
			queueChan <- message
			waitingMessages++
			//repairVehicle.messageChan <- message
			//zrobić osobny kanał na wiadomości, które nie mogły się wykonać
		}

		for _, s := range routeSwitches {
			responseSwitches[s] <- int32(REPAIRVEHICLE)
		}
		for _, l := range route {
			if l < len(lines) {
				responseLines[l] <- int32(REPAIRVEHICLE)
			} else {
				responsePlatforms[l-len(lines)+1] <- int32(REPAIRVEHICLE)
			}
		}

		for _, p := range routePlatforms {
			responsePlatforms[p] <- int32(REPAIRVEHICLE)
		}

	}
}

func startTrain(pos int) {
	trains[pos].position = 0

	channelLine := make(chan int32)
	channelSwitch := make(chan int32)
	messageLine := Message{id: trains[pos].id, response: channelLine}
	messageSwitch := Message{id: trains[pos].id, response: channelSwitch}

	size := len(trains[pos].route)
	var prevJunction, junction Switch

	index := trains[pos].route[trains[pos].position]

	if index >= len(lines) {
		index = index - len(lines) + 1
		platform := platforms[index]
		platform.c <- messageLine
		trains[pos].logs = append(trains[pos].logs, Log{
			trainId: trains[pos].id,
			typeId:  2,
			value:   platform.id})
		timeToWait := time.Duration(platform.minLayTime / 60.0 * secPerHour)
		time.Sleep(timeToWait * time.Second)
	} else {
		line := lines[index]
		line.c <- messageLine
		trains[pos].logs = append(trains[pos].logs, Log{
			trainId: trains[pos].id,
			typeId:  1,
			value:   line.id})

		var speed int
		if trains[pos].maxSpeed <= line.maxSpeed {
			speed = trains[pos].maxSpeed
		} else {
			speed = line.maxSpeed
		}
		timeToWait := time.Duration(line.lenght / speed * secPerHour)
		time.Sleep(timeToWait * time.Second)
	}

	for running {
		oldPosition := trains[pos].position
		trains[pos].position = (oldPosition + 1) % size
		possibleJunctions := junctions[trains[pos].route[oldPosition]][trains[pos].route[trains[pos].position]]
		if len(possibleJunctions) == 1 {
			prevJunction = junction
			junction = switches[possibleJunctions[0]]
		} else {
			if possibleJunctions[0] != int(prevJunction.id) {
				prevJunction = junction
				junction = switches[possibleJunctions[0]]
			} else {
				prevJunction = junction
				junction = switches[possibleJunctions[1]]
			}
		}

		junction.c <- messageSwitch

		channelLine <- trains[pos].id //free line

		trains[pos].logs = append(trains[pos].logs, Log{
			trainId: trains[pos].id,
			typeId:  0,
			value:   junction.id})

		time.Sleep(time.Duration(junction.minUsageTime/60.0*secPerHour) * time.Second)

		index := trains[pos].route[trains[pos].position]

		if index >= len(lines) {
			index = index - len(lines) + 1
			platform := platforms[index]
			platform.c <- messageLine
			channelSwitch <- trains[pos].id //free swich
			for _, listenerChan := range trains[pos].listeners {
				listenerChan <- platform.station
			}
			trains[pos].logs = append(trains[pos].logs, Log{
				trainId: trains[pos].id,
				typeId:  2,
				value:   platform.id})

			timeToWait := time.Duration(platform.minLayTime / 60.0 * secPerHour)
			time.Sleep(timeToWait * time.Second)
		} else {
			line := lines[index]
			line.c <- messageLine
			channelSwitch <- trains[pos].id //free swich
			trains[pos].logs = append(trains[pos].logs, Log{
				trainId: trains[pos].id,
				typeId:  1,
				value:   line.id})

			var speed int
			if trains[pos].maxSpeed <= line.maxSpeed {
				speed = trains[pos].maxSpeed
			} else {
				speed = line.maxSpeed
			}
			timeToWait := time.Duration(line.lenght / speed * secPerHour)
			time.Sleep(timeToWait * time.Second)
		}
	}

	wg.Done()
}

func taskLine(line Line) {
	for running {
		if !line.damaged {
			message := <-line.c
			line.status = message.id
			if printing {
				fmt.Println("Line ", line.id, " taken by train", message.id)
			}
			r := <-message.response
			if printing {
				fmt.Println("Train ", r, " exited line ", line.id)
			}
			line.status = EMPTY
		} else {
			time.Sleep(time.Duration(100) * time.Millisecond)
		}
	}

	wg.Done()
}

func taskPlatform(platform Platform) {
	for running {
		if !platform.damaged {
			message := <-platform.c
			platform.status = message.id
			if printing {
				fmt.Println("Platform ", platform.id, " taken by train", message.id)
			}
			r := <-message.response
			if printing {
				fmt.Println("Train ", r, " exited platform ", platform.id)
			}
			platform.status = EMPTY
		} else {
			time.Sleep(time.Duration(100) * time.Millisecond)
		}
	}

	wg.Done()
}

func taskSwitch(s Switch) {
	for running {
		if !s.damaged {
			message := <-s.c
			s.status = message.id
			if printing {
				fmt.Println("Switch ", s.id, " taken by train ", message.id)
			}
			r := <-message.response
			if printing {
				fmt.Println("Train ", r, " exited switch ", s.id)
			}
			s.status = EMPTY
		} else {
			time.Sleep(time.Duration(100) * time.Millisecond)
		}
	}

	wg.Done()
}
