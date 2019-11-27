/***
* Name: highestutilitystage
* Author: Viktoriya and Milko
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model highestutilitystage

/* Insert your model definition here */
global {
	init {
		create Stage number: 2;
		create Guest number: 1 {
			isLeader <- true;
		}
		
		create Guest number: 1 {
			crowdMass <- 1.0;
		}
		create Guest number: 1 {
			crowdMass <- 0.0;
		}
		create Guest number: 1 {
			crowdMass <- 0.0;
		}
		
	}
}

species Stage skills: [fipa] {
	
	float lightShow;
	float speakers;
	float band;
	float fireworks;
	float sittingSpots;
	float toiletsNearby;
	
	bool startAConcert;
	int showDuration <- -1;
	int showTimer <- 0;
	
	reflex startShow when: !startAConcert {
		startAConcert <- flip(1);
		if(startAConcert) {
			do announceShow;
		}
	}

	action announceShow {
		do initializeShowParameters;
		do informGuestsThatShowIsStarting;
	}
	
	action initializeShowParameters {
		showDuration <- rnd(75, 90);
		write "Time (" + time + "): " + name + " start hosting a show with duration " + showDuration;
		lightShow <- rnd(0.1, 0.9) with_precision 1;
		speakers <- rnd(0.1, 0.9) with_precision 1;
		band <- rnd(0.1, 0.9) with_precision 1;
		fireworks <- rnd(0.1, 0.9) with_precision 1;
		sittingSpots <- rnd(0.1, 0.9) with_precision 1;
		toiletsNearby <- rnd(0.1, 0.9) with_precision 1;
		write name + " parameters: lightShow " + lightShow + "; speakers: " + speakers + "; band: " + band
			+ " ; fireworks: " + fireworks + "; sittingSpots: " + sittingSpots + "; toiletsNearby: " + toiletsNearby;
	}
	
	action informGuestsThatShowIsStarting {
		list<Guest> allGuests <- Guest at_distance(100);
		if (allGuests != nil and !empty(allGuests)) {
			map<string, float> parametersMap <- map<string, float>("lightShow"::lightShow, "speakers"::speakers, "band"::band, 
			"fireworks"::fireworks, "sittingSpots"::sittingSpots, "toiletsNearby"::toiletsNearby);
			write parametersMap;
			write "Time (" + time + "): " + name + " send msg about show with duration " + showDuration;
			do start_conversation to:  allGuests protocol: 'fipa-contract-net' performative: 'inform' contents: [parametersMap];
		}
	}
	
	reflex endShow when: showDuration = showTimer {
		write "Time (" + time + "): " + name + " is ending the show.";
		startAConcert <- false;
		showDuration <- -1;
		showTimer <- 0;
		
		do informGuestsThatShowIsEnding;
	}
	
	action informGuestsThatShowIsEnding {
		list<Guest> guestsAttendingShow <- Guest at_distance(0); //guest that are in the square
		if (guestsAttendingShow != nil and !empty(guestsAttendingShow)) {
			do start_conversation to: guestsAttendingShow protocol: 'fipa-request' performative: 'request' contents: ['Get out of venue'];
			write name + " informs guests " + guestsAttendingShow + " that show is ending.";
		}
	}
	
	// keep the order of endShow reflex and handleShowDuration - this way when we update the show timer on the next round it will end it.
	reflex handleShowDuration when: startAConcert {
		showTimer <- showTimer + 1;
	} 
	
	rgb stageColor <- #green;
	
	aspect default {
		draw pyramid(5) at: location color: stageColor;
	}
}

species Guest skills: [moving, fipa] {
	
	float lightShow <- rnd(0.1, 0.9) with_precision 1;
	float speakers <- rnd(0.1, 0.9) with_precision 1;
	float band <- rnd(0.1, 0.9) with_precision 1;
	float fireworks <- rnd(0.1, 0.9) with_precision 1;
	float sittingSpots <- rnd(0.1, 0.9) with_precision 1;
	float toiletsNearby <- rnd(0.1, 0.9) with_precision 1;
	
	float crowdMass <- flip(0.5) ? 1.0 : 0.0;
	
	bool isAttendingAStage <- false;
	Stage attendedStage;
	
	bool isLeader;
	bool hasSentMsg;
	
	map<Stage, float> utilityPerStage;
	
	reflex inform_agents_who_is_leader when: isLeader and !hasSentMsg {
		write '(Time ' + time + '): ' + name + ' leader sending proposal';
		do start_conversation to: Guest at_distance(100) protocol: 'fipa-propose' performative: 'propose' contents: ['Will you give me your utility?'] ;
		hasSentMsg <- true;
	}
	
	reflex accept_utilities_from_guests when: !empty(accept_proposals) and isLeader {
		
		write '(Time ' + time + '): ' + name + ' leader accepting proposals';
		
		list<Guest> allGuests <- accept_proposals collect (each.sender as Guest);
		write name + ' receives accept_proposal messages';
		loop i over: accept_proposals {
			string test <- string(i.contents);
		}
		
		map<Stage, list<Guest>> guestsPerStage <- constructGuestsPerStageMap(allGuests);
		
		write 'Number of guests per stage ' + guestsPerStage;
		do calculateGlobalUtilityAndUpdateMaxStageForGuests(allGuests, guestsPerStage);
		
		write 'is it because of the queues..';
		map<Stage, list<Guest>> guestsPerStageWithCrowd <- constructGuestsPerStageMap(allGuests);
		write 'Number of guests per stage ' + guestsPerStageWithCrowd;
		do calculateGlobalUtilityAndUpdateMaxStageForGuests(allGuests, guestsPerStageWithCrowd);
	}
	
	map<Stage, list<Guest>> constructGuestsPerStageMap(list<Guest> allGuests) {
		map<Stage, list<Guest>> guestsPerStage <- [];
		write 'map: ' + guestsPerStage + '; allGuests: ' + allGuests;
		loop g over: allGuests {
			write 'guest stage: ' + g.attendedStage;
			Stage s <- g.attendedStage as Stage;
			write 'attended ' + s;
			if (guestsPerStage[s] != nil) {
				list<Guest> guestOfThisStage <- guestsPerStage[s];
				add g to: guestOfThisStage;
				add s::list<Guest>(guestOfThisStage) to: guestsPerStage;
			} else {
				add s::list<Guest>(g) to: guestsPerStage;
			}
		}
		return guestsPerStage;
	}
	
	action calculateGlobalUtilityAndUpdateMaxStageForGuests(list<Guest> allGuests, map<Stage, list<Guest>> guestsPerStage) {
		map<Stage, list<Guest>> guestsPerStageGlobalUtility;
		float globalUtility;
		list<Stage> allStages <- Stage at_distance(100);
		loop g over: allGuests {
			map<Stage, float> tempUtilityPerStage <- g.utilityPerStage;
			write 'utility per stage ' + utilityPerStage;
			loop s over: allStages {
				float utility <- tempUtilityPerStage[s];
				
				if (guestsPerStage[s] != nil) {
						write 'stage in loop ' + s + "; guests per stage " + guestsPerStage[s];
						if ((length(guestsPerStage[s]) >= 2 and g.crowdMass > 0.5) or 
							(length(guestsPerStage[s]) < 2 and g.crowdMass < 0.5)) {
							utility <- utility + 1 with_precision 1;
						} else if ((length(guestsPerStage[s]) >= 2 and g.crowdMass < 0.5) or 
							(length(guestsPerStage[s]) < 2 and g.crowdMass > 0.5)) {
							utility <- utility - 1 with_precision 1;
						}
						
						put utility at: s in: tempUtilityPerStage;
						write 'adding stage ' + s + " and utility " + utility + " to " + tempUtilityPerStage;
					}
				}
				write 'tempUtilityPerStage ' + tempUtilityPerStage;
				
				float initUtility <- 0.0;
				Stage maxStage;
				loop i over: tempUtilityPerStage.keys {
					if (tempUtilityPerStage[i] > initUtility) {
						initUtility <- tempUtilityPerStage[i];
						maxStage <- i;
					}
				}
				
				g.attendedStage <- maxStage; // send it as a message
				write 'stage with max utility ' + maxStage;
				globalUtility <- globalUtility + g.utilityPerStage[maxStage] as float;
			}
		write 'Current global utility with crowd mass parameter without moving agents is: ' + (globalUtility);
	}
	
	reflex read_propose_from_leader when: !empty(proposes) and !isLeader and attendedStage != nil {
		write name + ' read proposal from leader';
		message p <- proposes[0];
		if (attendedStage != nil) {
			do accept_proposal message: p contents: [utilityPerStage] ;
		}
	}
	
	reflex read_inform when: !empty(informs) and !isAttendingAStage {
		write '(Time ' + time + '): ' + name + ' receives ' + informs;
		list<Stage> stages <- informs collect (each.sender);
		
		loop s over: stages {
			add s::calculateStageUtilityFunction(s) to:utilityPerStage;
		}
		Stage stageWithMaxUtility <- stages with_max_of (calculateStageUtilityFunction(each));
		write 'Stage with max utility is ' + stageWithMaxUtility.name;
		attendedStage <- stageWithMaxUtility;
//		isAttendingAStage <- true;
		
		loop i over: informs {
			Stage stage <- i.sender;
			write '(Time ' + time + '): ' + name + ' receives message with content: ' + (string(i.contents));
			do end_conversation message: i contents: ['Understood message from ' + agent(i.sender).name];
		}
	}
	
	float calculateStageUtilityFunction(Stage stage) {
		float utility <- (lightShow * stage.lightShow 
			+ speakers * stage.speakers 
			+ band * stage.band 
			+ fireworks * stage.fireworks
			+ sittingSpots * stage.sittingSpots
			+ toiletsNearby * stage.toiletsNearby) with_precision 1;
		write 'Time (' + time + ' ): ' + stage.name + ' has utility ' + utility + ' for guest ' + name;
		return utility;
	}
	
	reflex read_show_is_ending_message when: !empty(requests) and isAttendingAStage {
		write '(Time ' + time + '): ' + name + ' receives request to leave stage.';
		loop r over: requests {
			Stage stage <- r.sender as Stage;
			write '(Time ' + time + '): ' + name + ' receives message with content: ' + (string(r.contents));
			do agree message: r contents: ['I am going away'];
			isAttendingAStage <- false;
		}
	}
	
	reflex goToPreferredStage when: isAttendingAStage {
		do goto target:attendedStage; 
	}
	
	reflex dance when: !isAttendingAStage {
		do wander;
	}
	
	rgb myColor <- #red;
	
	aspect default {
		draw sphere(1) at: location color: myColor;
	}
}

experiment highestutilitystage_experiment type: gui {
	output {
		display displayFest type: opengl {
			species Guest;
			species Stage;
		}	
	}
}