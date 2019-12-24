/***
* Name: festival
* Author: Viktoriya and Milko
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model festival

/* Insert your model definition here */

global {
	string TAKE_PICTURE_OF_STAGE <- "Taking a picture of stage";
	string SAY_HI_TO_COLLEAGUE <- "Hello, colleague photographer";
	string SAY_HI_TO_MERCHANT <- "Hello, fellow merchant!";

	string DRINK_OFFER <- "Let's drink";
	string ACCEPT_DRINK <- "OK! Let's have one!";
	string DECLINE_DRINK <- "Unfortunately, I have to work!";

	string NO_MORE_BEER -> "I do not have more beer";
	string BEER_IN_STOCK -> "Here you are!";
	string SECURITY_GUARD_HEADING_TO_YOU <- "I will catch you!";
	string SECURITY_GUARD_CAUGHT_YOU <- "Go to prison.";
	

	string ASK_MERCHANT_FOR_OFFER <- "I would like to buy something.";
	string MERCHANT_MAKES_AN_OFFER <- "You can buy merchandise now.";
	string MERCHANT_IS_NOT_WORKING <- "Sorry, I am not working.";
	string BUY_MERCHANDISE <- "I will buy this.";
	string DO_NOT_BUY_MERCHANDISE <- "I will not buy this, sorry.";
	string MERCHANT_NOT_TRUSTWORTHY <- "You are not trustworthy.";
	float MERCHANT_WORKING_AT_BAR <- 0.2;

	string PICTURE_QUERY <- "Would you take a picture of me?";
	string PHOTOGRAPHER_OFFERS_TO_TAKE_A_PHOTO <- "I will take a picture of you.";
	string ACCEPT_PHOTO <- "Sure, go ahead!";
	string DECLINE_PHOTO <- "No, I am not in the mood.";

	int TOILET_URGENCY <- 60;
	int TOILET_URGENCY_THRESHOLD <- 40;
	int TIME_PER_GUEST_IN_TOILET <- 15;
	string TOILET_IS_FREE <- "Now is your turn.";
	string TOILET_IS_TAKEN <- "There is somebody before you";
	string GET_OUT_OF_TOILET <- "Your turn in the toilet has ended.";
	string QUEUE_MOVING_FORWARD <- "The queue is moving, you can move.";

	int numOfGuests -> {length(DancingGuest) + length(ChillingGuest) + length(Photographer)};
    int amusedGuests update: DancingGuest count (each.happiness > 0.8) 
    						+ ChillingGuest count (each.happiness > 0.8)
    						+ Photographer count (each.happiness > 0.8);

    int drunkPeople update: DancingGuest count (each.drunkness > 0.8) 
    						+ ChillingGuest count (each.drunkness > 0.8)
    						+ Photographer count (each.drunkness > 0.8);

	
	float initialLevel <- 2.25;
    float happinessLevel <- 0.0 update: 0.0;
	int globalWaitingTime <- 0 update: 0;
	
	int numberOfGuests <- 10;
	int barsNum <- 20;
	int stageNum <- 20;
	int toiletsNum <- 10;
	int currentBarsNum -> {length(Bar)};
	
	// print debug logs or not
	bool debug <- true;
	
	point prisonLocation <- {90.0, 90.0};
	
	list<string> musicTypes <- ["rock", "pop", "jazz"];

	init {
		create DancingGuest number: numberOfGuests;
		create ChillingGuest number: numberOfGuests;
		create Photographer number: numberOfGuests;
//		create SecurityGuard number: numberOfGuests;
		create Merchant number: numberOfGuests;
		create Bar number: barsNum;
		create Prison number: 1;
		create Stage number: stageNum;
		create Toilet number: toiletsNum;
	}
}

/**
 * Gues Species
 */
species Guest skills: [moving, fipa] {
	
	reflex updateHappiness {
		happinessLevel <- happinessLevel + happiness;
	}
	
	reflex updateWaitingTime {
		globalWaitingTime <- globalWaitingTime + waitingTime;
	}
	
	image_file my_icon;
	
	rgb myColor <- #red;
	float happiness <- 0.0 with_precision 2;
	float drunkness <- 0.0 with_precision 2;
	float loudness <- rnd(0.5, 1.0) with_precision 2;
	bool prefersCompany <- flip(0.5);
	bool hasRequestedToUseToilet <- false;
	bool canEnterToilet <- false;
	
	int waitingTime;
	
	int toiletUrgency <- TOILET_URGENCY update: cycle mod 20 = 0 ? toiletUrgency - rnd(1, 5) : toiletUrgency;
	
	int size <- 1;
	
	float goToBar <- 0.2 with_precision 2;
	float goToStage <- 0.2 with_precision 2;
	bool goToPrison <- false;
	
	Stage currentStage <- nil;
	Bar currentBar <- nil;
	point randomPoint <- nil;
	Toilet currentToilet <- nil;

	point target <- nil;
	
	int TIME_AT_BAR <- 100;
	int TIME_AT_STAGE <- 100;
	int TIME_AT_PRISON <- 10;
	
	int timeAtBar <- TIME_AT_BAR update: isAtBar() ? timeAtBar - 1 : timeAtBar min: 0;
	int timeAtStage <- TIME_AT_STAGE update: isAtStage() ? timeAtStage - 1 : timeAtStage min: 0;
	int timeAtPrison <- TIME_AT_PRISON update: isAtPrison() ? timeAtPrison - 1 : timeAtPrison min: 0;
	
	aspect info {
		draw sphere(size) at: location color: myColor border: #black;
		draw string(happiness with_precision 2) size: 3 color: #black;
	}
	
	aspect icon {
		draw my_icon size: 2 * size;
	}
	
	reflex defaultBehaviour when: currentStage = nil and currentBar = nil and currentToilet = nil {
		do wander;
		if (toiletUrgency < TOILET_URGENCY_THRESHOLD) {
			currentToilet <- one_of(Toilet);
			target <- currentToilet.toiletEntrance;
		} else if (randomPoint != nil) {
			do goto target: randomPoint;
			if (self.location = randomPoint) {
				randomPoint <- nil;
			}
		} else if (goToPrison) {
			do goto target: one_of(Prison);
		} else if (flip(goToStage)) {
			currentStage <- one_of(Stage);
		} else if (flip(goToBar)) {
			currentBar <- one_of(Bar);
		}
	}
	
	// Bar related
	reflex goToBar when: currentBar != nil {
		do goto target: currentBar;
	}
	
	reflex isAtBar when: isAtBar() {
		if (timeAtBar = 0) {
			do endTimeAtBar;
		}
	}
	
	action endTimeAtBar {
		timeAtBar <- TIME_AT_BAR;
		currentBar <- nil;
		randomPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
	}
	
	bool isAtBar {
		return currentBar != nil and location = currentBar.location;
	}
	
	// Stage related
	reflex goToStage when: currentStage != nil {
		do goto target: currentStage;
	}
	
	reflex isAtStage when: isAtStage() {
		if (timeAtStage = 0) {
			do endTimeAtStage;
		}
	}
	
	action endTimeAtStage {
		timeAtStage <- TIME_AT_STAGE;
		currentStage <- nil;
		randomPoint <- { rnd(0.0, 100.0), rnd(0.0, 100.0) };
	}
	
	bool isAtStage {
		return currentStage != nil and location = currentStage.location;
	}
	
	
	// Prison related
	bool isAtPrison {
		Prison prison <- one_of(Prison);
		list<agent> agentsInPrison <- agents_overlapping(prison);
		return agentsInPrison contains self;
	}
	
	// Toilet related
	reflex goToToiletEntrance when: currentToilet != nil and !isAtToiletEntrance() {
//		do goto target: currentToilet.toiletEntrance;
//		target <- currentToilet.toiletEntrance;
	}
	
	reflex enterToilet when: canEnterToilet {
//		do goto target: currentToilet;
	}
	
	reflex isAtToiletEntrance when: isAtToiletEntrance() and !hasRequestedToUseToilet {
		do start_conversation to:[currentToilet] protocol: "fipa-request" performative: "request" contents:["I need to go to the bathroom, NOW!!!"];
		hasRequestedToUseToilet <- true;
	}
	
	action endTimeInToilet {
		toiletUrgency <- TOILET_URGENCY;
		hasRequestedToUseToilet <- false;
		canEnterToilet <- false;
		currentToilet <- nil;
		randomPoint <- { rnd(0.0, 100.0), rnd(0.0, 100.0) };
		target <- nil;
		waitingTime <- 0;
	}
	
	bool isAtToiletEntrance {
		return currentToilet != nil and location = currentToilet.toiletEntrance;
	}
	
	
	bool isBad {
		return drunkness > 0.8 and loudness > 0.8;
	}
	
	action drinkBeer(int quantity) {
		happiness <- happiness + 0.1 * (quantity);
		drunkness <- drunkness + 0.1;
	}
	
	action handleBeerSentFromFriend {
		// if I am a friend of the other dancing guy
		loop i over: informs {
			string msg <- i.contents[0] as string;
			// after a friend orders a beer for me, the bar sends an inform message whether there is more beer left or not
			if (msg = BEER_IN_STOCK) {
				write name + " drinks";
				do drinkBeer(i.contents[1] as int);
				do end_conversation message: i contents: ["Alright."];
			} else if (msg = NO_MORE_BEER) {
				happiness <- happiness - 0.1 * (i.contents[1] as int);
				do end_conversation message: i contents: ["Alright."];
			}
		}
	}
	
	reflex handleToiletInteractions {
		loop i over: informs {
			string senderType <- string(type_of(i.sender));
			switch(senderType) {
				match Toilet.name {
					string msg <- i.contents[0] as string;
		 			if (msg = GET_OUT_OF_TOILET) {
						do endTimeInToilet;
						do end_conversation message: i contents: ["Alright."];
					} else if (msg = QUEUE_MOVING_FORWARD) {
						waitingTime <- waitingTime + 1;
						write "Time[" + time + "]: " + name + " moves forward to enter toilet.";
						
						// has reached the place it was supposed to take in the queue
						if (location = target) {
							float newLocationX <- location.x + 6.0;
							if (newLocationX >= Toilet(i.sender).toiletEntrance.x) {
								newLocationX <- Toilet(i.sender).toiletEntrance.x;
							}
							target <- {newLocationX, location.y};
						}
					}
				}
			}
		}
		
		loop agree over: agrees {
			write "Time[" + time + "]: " + name + " receives agrees.";
			string senderType <- string(type_of(agree.sender));
			switch(senderType) {
				match Toilet.name {
					string msg <- agree.contents[0] as string;
		 			if (msg = TOILET_IS_FREE) {
		 				write "Time[" + time + "]: " + name + " can enter toilet.";
		 				happiness <- happiness + 0.5;
		 				canEnterToilet <- true;
		 				target <- currentToilet.location;
					}
				}
			}
		}
		
		loop refuse over: refuses {
			string senderType <- string(type_of(refuse.sender));
			switch(senderType) {
				match Toilet.name {
					string msg <- refuse.contents[0] as string;
		 			if (msg = TOILET_IS_TAKEN) {
		 				waitingTime <- waitingTime + 1;
		 				happiness <- happiness - 0.5;
		 				int queueSize <- length(currentToilet.queue);
		 				float xPoint <- 0.0;
		 				if (queueSize <= 1) {
		 					xPoint <- currentToilet.location.x;
		 				} else {
		 					int lastIndex <- length(currentToilet.queue) - 2;
		 					Guest lastGuestOnQueue <- currentToilet.queue[lastIndex];
		 					write "Guest " + lastGuestOnQueue.name + " on location " + lastGuestOnQueue.location;
		 					write "Guest " + lastGuestOnQueue.name + " target " + lastGuestOnQueue.target;
		 					xPoint <- lastGuestOnQueue.target.x;
		 				}
		 				
		 				target <- {(xPoint - 4.0) with_precision 2, currentToilet.location.y};
		 				write name + " enter queue at location " + target;
					}
				}
			}
		}	
	}
	
	reflex moveToTarget when: target != nil {
		do goto target: target;
	}
}

species DancingGuest parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/dancing-person.png");
	rgb myColor <- #purple;
	
	float adventurous <- rnd(0.5, 1.0) with_precision 2;
	float confident <- rnd(0.5, 1.0) with_precision 2;
	float generous <- rnd(0.5, 1.0) with_precision 2;
	
	// USE THIS ONE WHEN INTERACTING WITH SECURITY GUARDS
	bool isFollowingGuest <- false;
	
	bool hasApproachedMerchant <- false;

	reflex isAtBarReflex when: isAtBar() {
		do handleInteractions;
		//approach merchant only once per stay at the bar
		if (timeAtBar mod 30 = 0) {
			hasApproachedMerchant <- false;
		}
		if (timeAtBar mod 5 = 0) {
			do startInteractionsAtBar;
		}
	}
	
	reflex isAtStageReflex when: isAtStage() {
		do handleInteractions;
		if (timeAtStage mod 10 = 0) {
			do startInteractionsAtStage;
		}
	}
	
	action handleInteractions {
		// handle responses for started conversations
		//at bar receiving positive response from either ChillGuest or Photographer or Bar
		loop agree over: agrees {
			string senderType <- string(type_of(agree.sender));
			switch(senderType) {
				match ChillingGuest.name {
					if (agree.contents[0] = "BAR" and agree.contents[1] = currentBar) {
						do askBarForBeerForMyFriend(2, agree.sender);
					} else if (agree.contents[0] = "STAGE" and agree.contents[1] = currentStage) {
						happiness <- happiness + 0.05;
					}
				}
				match Photographer.name {
					if (agree.contents[0] = "BAR" and agree.contents[1] = currentBar) {
						happiness <- happiness + 0.05;
					} else if (agree.contents[0] = "STAGE" and agree.contents[1] = currentStage) {
						happiness <- happiness + 0.05;
					}
				}
				match Bar.name {
					do drinkBeer(agree.contents[1] as int);
				}
			}
			string msgContent <- agree.contents[0];
		}
		
		loop reject over: reject_proposals {
			string senderType <- string(type_of(reject.sender));
			switch(senderType) {
				match ChillingGuest.name {
					if (reject.contents[0] = "STAGE" and reject.contents[1] = currentStage) {
						happiness <- happiness - 0.1;
						write "Time[" + time + "]: " + name + " is not dancing anymore with " + reject.sender + " :("; 
						if (shouldFollowChillingGuest()) {
							write "Time[" + time + "]: " + name + " is now following " + reject.sender + "... Creepy";
							isFollowingGuest <- true;
							do start_conversation to: [reject.sender] protocol: 'no-protocol' performative: 'inform' 
								contents: ["STAGE", currentStage, "You shouldn't have refused me!", cycle];
							
						}
					}
				}
			}
		}
		
		//at bar receiving negative response from either ChillGuest or Photographer or Bar
		loop refuse over: refuses {
			string senderType <- string(type_of(refuse.sender));
			switch(senderType) {
				match ChillingGuest.name {
					if (refuse.contents[0] = "BAR" and refuse.contents[1] = currentBar) {
						happiness <- happiness - 0.1;	
					}
				}
				match Photographer.name {
					if (refuse.contents[0] = "BAR" and refuse.contents[1] = currentBar) {
						happiness <- happiness - 0.05;
					} else if (refuse.contents[0] = "STAGE" and refuse.contents[1] = currentStage) {
						happiness <- happiness - 0.05;
					}
				}
				match Bar.name {
					happiness <- happiness - 0.1 * (refuse.contents[1] as int);
				}
				//after approaching the Merchant for an offer, if he is not working, we receive a refuse 
				match Merchant.name {
					if (refuse.contents[0] = "BAR" and refuse.contents[1] = currentBar) {
						write "Time[" + time + "]: " + name + " receives a refuse from merchant " + refuse.sender;
						happiness <- happiness - 0.05;
					}
				}
			}
			string msgContent <- refuse.contents[0];
		}
		
		//at bar meeting another dancing guest that invites us to drink with them;
		//current dancing guest is asking bar for beers for both current and the friend that invited us to drink
		loop propose over: proposes {
			string senderType <- string(type_of(propose.sender));
			switch(senderType) {
				match DancingGuest.name {
					if (propose.contents[0] = "BAR" and propose.contents[1] = currentBar) {
						write name + " location of sender is current bar " + currentBar.name;
						do accept_proposal message: propose contents: ["OK! It's on me!"];
						do askBarForBeerForMyFriend(2, propose.sender);	
					} else if (propose.contents[0] = "STAGE" and propose.contents[1] = currentStage) {
						string msg <- "Yes, let's dance!";
						do accept_proposal message: propose contents: [msg];
						write name + " is dancing now at stage " + currentStage.name + " with " + propose.sender + ". Sends a response: " + msg;
						// TODO maybe add countdown?
						do danceAtStage;
					}
				}
				//after approaching the Merchant for an offer, if he is working, he makes a proposal to the dancing guest 
				match Merchant.name {
					if (propose.contents[0] = "BAR" and propose.contents[1] = currentBar) {
						write "Time[" + time + "]: " + name + " receives a proposal from merchant " + propose.sender;
						if (shouldBuyFromMerchantAtBar(Merchant(propose.sender))) {
							write "Time[" + time + "]: " + name + " is buying from " + propose.sender;
							do accept_proposal message: propose contents: ["BAR", currentBar, BUY_MERCHANDISE];
							happiness <- happiness + 0.1;
						} else {
							write "Time[" + time + "]: " + name + " is not buying from " + propose.sender;
							do reject_proposal message: propose contents: ["BAR", currentBar, MERCHANT_NOT_TRUSTWORTHY];
						}
					} else if (propose.contents[0] = "STAGE" and propose.contents[1] = currentStage) {
						write "Time[" + time + "]: " + name + " receives a proposal from merchant " 
							+ propose.sender + " at stage " + currentStage.name;
						if (propose.contents[2] =  MERCHANT_MAKES_AN_OFFER and shouldBuyFromMerchantAtStage(Merchant(propose.sender))) {
							write "Time[" + time + "]: " + name + " is buying from " + propose.sender + " at stage " + currentStage;
							do accept_proposal message: propose contents: ["STAGE", currentStage, BUY_MERCHANDISE];
							happiness <- happiness + 0.1;
						} else {
							write "Time[" + time + "]: " + name + " is not buying from " + propose.sender + " at stage " + currentStage;
							do reject_proposal message: propose contents: ["STAGE", currentStage, DO_NOT_BUY_MERCHANDISE];
						}
					}
				}
				// after being approached by the photographer for a picture, accept it or decline it
				match Photographer.name {
					if (propose.contents[0] = "BAR" and propose.contents[1] = currentBar and propose.contents[2] = PHOTOGRAPHER_OFFERS_TO_TAKE_A_PHOTO) {
						write "Time[" + time + "]: " + name + " is offered a picture from " + propose.sender;
						if (shouldAcceptPicture()) {
							write "Time[" + time + "]: " + name + " is accepting a picture from " + propose.sender;
							do accept_proposal message: propose contents: ["BAR", currentBar, ACCEPT_PHOTO];
						} else {
							write "Time[" + time + "]: " + name + " is declining a picture from " + propose.sender;
							do reject_proposal message: propose contents: ["BAR", currentBar, DECLINE_PHOTO];
						}
					} else if (propose.contents[0] = "STAGE" and propose.contents[1] = currentStage and propose.contents[2] = PHOTOGRAPHER_OFFERS_TO_TAKE_A_PHOTO) {
						write "Time[" + time + "]: " + name + " is accepting a picture from " + propose.sender;
						do accept_proposal message: propose contents: ["STAGE", currentStage, ACCEPT_PHOTO];
						happiness <- happiness + 0.05;
					}
				}
			}
			string msgContent <- propose.contents[0];
		}
		
		// at bar, security guard reaches us and our happiness goes down
		loop request over: requests {
			if (request.contents[0] = SECURITY_GUARD_CAUGHT_YOU) {
				happiness <- happiness - 0.3;
			}
		}
		
		do handleBeerSentFromFriend;
	}

	action startInteractionsAtBar {
		list<agent> agentsAtBar <- agents_overlapping(currentBar);
		remove self from: agentsAtBar;
		if (empty(agentsAtBar) or length(agentsAtBar) = 0) {
			do aloneAtBar;
		} else {
			loop agentAtBar over: agentsAtBar {
				string agentType <- string(type_of(agentAtBar));
				switch(agentType) {
					match DancingGuest.name {
						do meetDancingGuestAtBar(agentAtBar as DancingGuest);
					}
					match ChillingGuest.name {
						do meetChillingGuestAtBar(agentAtBar as ChillingGuest);
					}
					match Photographer.name {
						do meetPhotographerAtBar(agentAtBar as Photographer);
					}
					match Merchant.name {
						do meetMerchantAtBar(agentAtBar as Merchant);
					}
				}
			}
		}

		if (loudness > 0.8 and drunkness > 0.8) {
			write name + " is drunk and lound and attracts guard";
			SecurityGuard securityGuard <- one_of(SecurityGuard);
			if (securityGuard != nil) {
				do start_conversation to: [securityGuard] 
				protocol: "no-protocol" 
				performative: "inform" 
				contents: ["BAR", currentBar, "Catch me if you can."];
			}
		}
	}

	action startInteractionsAtStage {
		list<agent> agentsAtStage <- agents_overlapping(currentStage);
		remove self from: agentsAtStage;
		if (empty(agentsAtStage) or length(agentsAtStage) = 0) {
			do aloneAtStage;
		} else {
			loop agentAtStage over: agentsAtStage {
				string agentType <- string(type_of(agentAtStage));
				switch(agentType) {
					match DancingGuest.name {
						do meetDancingGuestAtStage(agentAtStage as DancingGuest);
						write "[Time: " + time + "] " + name + " is dancing now at stage " + currentStage.name + " with " + agentAtStage.name;
						do danceAtStage;
					}
					match ChillingGuest.name {
						do meetChillingGuestAtStage(agentAtStage as ChillingGuest);
						write "[Time: " + time + "] " + name + " is dancing now at stage " + currentStage.name + " with " + agentAtStage.name;
					}
					match Photographer.name {
						do meetPhotographerAtStage(agentAtStage as Photographer);
						write "[Time: " + time + "] " + name + " is dancing now at stage " + currentStage.name + " with " + agentAtStage.name;
					}
				}
			}
		}
	}
	
	
	/*
	 * MEET DANCING GUEST
	 */
	 // At a bar
	action meetDancingGuestAtBar(DancingGuest d) {
		list<agent> initiators <- conversations collect (each.initiator);
		if (!(initiators contains d)) {
			string msg <- "Let's drink";
			write name + " starts drinking with " + d.name + " and sends message " + msg;
			do start_conversation to: [d] protocol: "fipa-propose" performative: "propose" 
				contents: ["BAR", currentBar, msg];
		}
	}
	
	// At a stage
	action meetDancingGuestAtStage(DancingGuest d) {
		list<agent> initiators <- conversations collect (each.initiator);
		if (!(initiators contains d)) {
			string msg <- "Let's dance together!";
			write name + " starts dancing with " + d.name + " at stage " + currentStage.name + " and sends message " + msg;
			do start_conversation to: [d] protocol: "fipa-propose" performative: "propose" 
				contents: ["STAGE", currentStage, msg];
		}
	}
	
	
	/*
	 * MEET CHILLING GUEST
	 */
	 // At a bar
	action meetChillingGuestAtBar(ChillingGuest g) {
		if (generous > 0.8) {
			write "Time [" + time + "]: " + name + " offers a beer to " + g + " at location " + currentBar;
			do start_conversation to: [g] protocol: "fipa-query" performative: "query" 
				contents: ["BAR", currentBar, "Want a beer?"];
		}
	}
	
	// At a stage
	action meetChillingGuestAtStage(ChillingGuest g) {
		list<agent> initiators <- conversations collect (each.initiator);
		if (!(initiators contains g)) {
			string msg <- "Let's dance together!";
			write name + " starts dancing with " + g.name + " at stage " + currentStage.name + " and sends message " + msg;
			do start_conversation to: [g] protocol: "fipa-propose" performative: "propose" 
				contents: ["STAGE", currentStage, msg, cycle];
		}
	}
	
	// MEET PHOTOGRAPHER
	
	action meetPhotographerAtBar(Photographer p) {
		list<agent> initiators <- conversations collect (each.initiator);
		if ((!(initiators contains p)) and shouldAskForPictureAtBar()) {
			write name + " asks for a picture from " + p;
			do start_conversation to: [p] protocol: "fipa-query" performative: "query"
				contents: ["BAR", currentBar, PICTURE_QUERY];
		}
	}
	
	action meetPhotographerAtStage(Photographer p) {
		list<agent> initiators <- conversations collect (each.initiator);
		if ((!(initiators contains p)) and shouldAskForPictureAtStage()) {
			write name + " asks for a picture from " + p;
			do start_conversation to: [p] protocol: "fipa-query" performative: "query" 
				contents: ["STAGE", currentStage, PICTURE_QUERY];
		}
	}

	// MEET MERCHANT

	action meetMerchantAtBar(Merchant m) {
		if (shouldApproachMerchantAtBar()) {
			write "Time[" + time + "]: " + name + " approaches merchant " + m;
			do start_conversation to: list(m) protocol: 'fipa-contract-net' performative: 'cfp' contents: ["BAR", currentBar, ASK_MERCHANT_FOR_OFFER];
           	hasApproachedMerchant <- true;
   		}
   }
   
   action meetMerchantAtStage(Merchant m) {
		// TODO
   }
	
	action aloneAtBar {
		do askBarForBeer(1);
	}
	
	action aloneAtStage {
		// write what the agent is doing
		write name + " is dancing alone at stage" + currentStage.name;
		
		// decrease loudness
		loudness <- loudness - 0.01;
		
		// increase/decrease happiness based on prefers to be alone or not
		float newHappiness <- prefersCompany ? happiness + 0.01 : happiness - 0.01;
		
		if (debug) {
			write name + " happiness was: " + happiness + ", new happiness is: " 
				+ newHappiness + ". Loudness is now: " + loudness + " (was " + (loudness + 0.01) + ")."; 	
		} 
		
		happiness <- newHappiness;
	}
	
	/*
	 * Increase happiness when dancing!
	 */
	action danceAtStage {
		float happinessIncrement <- prefersCompany ? 0.2 : 0.1;
		happiness <- happiness + happinessIncrement;
		
		loudness <- loudness + 0.01;
		
		if (debug) {
			write name + " happiness is increased by " 
				+ happinessIncrement + " and is now " 
				+ happiness + " (was" + (happiness - happinessIncrement) + "). Loudness is increased by 0.01 to " + loudness;
		}
		
	}
	
	action askBarForBeerForMyFriend(int quantity, agent a) {
		write name + " and " + a.name + " are asking for a beer at bar " + currentBar.name;
		do start_conversation to: [currentBar] protocol: 'fipa-request' performative: 'request' contents: ["We would like beer.", quantity, a];
	}
	
	action askBarForBeer(int quantity) {
		write name + " is asking for a beer at bar " + currentBar.name;
		do start_conversation to: [currentBar] protocol: 'fipa-request' performative: 'request' contents: ["I would like beer.", quantity];
	}
	
	/*
	 * RULES
	 */
	 
	bool shouldFollowChillingGuest {
		write "HERE! at should follow";
		// Here loudness is equivalent to annoying
		return confident > 0.9 and loudness > 0.8;
	}

	bool shouldAskForPictureAtStage {
		return confident > 0.5;
	}

	bool shouldAskForPictureAtBar {
		return confident > 0.8;
	}

	bool shouldApproachMerchantAtBar {
		return confident > 0.5 and !hasApproachedMerchant;
	}

	bool shouldBuyFromMerchantAtBar(Merchant m) {
		return m.trustworthy > 0.3;
	}

	bool shouldBuyFromMerchantAtStage(Merchant m) {
		return generous > 0.6;
	}
	
	bool shouldAcceptPicture {
		return confident >= 0.5;
	}
}

species ChillingGuest parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/turtle.png");
	
	float cautious <- rnd(0.5, 1.0) with_precision 2;
	float nervous <- rnd(0.1, 0.3) with_precision 2;
	float positive <- rnd(0.1, 0.7) with_precision 2;
	
	reflex isAtBarReflex when: isAtBar() or isAtStage() {
		do handleInteractions;
	}
	
	reflex isAtBarToStartInteractionsReflex when: isAtBar() and timeAtBar mod 5 = 0 {
		do startInteractionsAtBar;
	}
	
	reflex isAtStageToStartInteractionsReflex when: isAtStage() and timeAtStage mod 5 = 0 {
		do startInteractionsAtStage;
	}
	
	action startInteractionsAtBar {
		write name + "start interactions at bar" + time;
		list<agent> agentsAtBar <- agents_overlapping(currentBar);
		remove self from: agentsAtBar;
		if (empty(agentsAtBar) or length(agentsAtBar) = 0) {
			do aloneAtBar;
		} else {
			loop agentAtBar over: agentsAtBar {
				string agentType <- string(type_of(agentAtBar));
				switch(agentType) {
					match DancingGuest.name {
						// TODO
//						do meetDancingGuestAtBar(agentAtBar as DancingGuest);
					}
					match ChillingGuest.name {
						// TODO
//						do meetChillingGuestAtBar(agentAtBar as ChillingGuest);
					}
					match Photographer.name {
						// TODO
//						do meetPhotographerAtBar(agentAtBar as Photographer);
					}
				}
			}
		}	
	}
	
	action startInteractionsAtStage {
		write name + "start interactions at stage " + time;
		list<agent> agentsAtStage <- agents_overlapping(currentStage);
		remove self from: agentsAtStage;
		if(empty(agentsAtStage) or length(agentsAtStage) = 0) {
			do aloneAtStage;
		} else {
			loop agentAtStage over: agentsAtStage {
				string agentType <- string(type_of(agentAtStage));
				switch(agentType) {
					match Photographer.name {
						do meetPhotographerAtStage(agentAtStage as Photographer);
					}
					match ChillingGuest.name {
						do meetChillingGuestAtStage(agentAtStage as ChillingGuest);
					}
				}
			}
		}
	}
	
	
	action handleInteractions {
		loop q over: queries {
			string senderType <- string(type_of(q.sender));
			switch senderType {
				match DancingGuest.name {
					if (q.contents[0] = "BAR" and q.contents[1] = currentBar) {
						do handleDancingGuestAtBar(q);
					} else if(q.contents[0] = "STAGE" and q.contents[1] = currentStage) {
						write "Here at handle interactions of the chilling guest after invite for dance";
						do handleDancingGuestAtStage(q);
					}
				}
				match ChillingGuest.name {
					// TODO not implemented
				}
			}
		}
		
		loop p over: proposes {
			string senderType <- string(type_of(p.sender));
			switch senderType {
				// meet a dancing guest at a stage, after his proposal to dance
				match DancingGuest.name {
					if(p.contents[0] = "STAGE" and p.contents[1] = currentStage) {
						write "Here at handle interactions of the chilling guest after invite for dance";
						do handleDancingGuestAtStage(p);
					}
				}
				match ChillingGuest.name {
					if (p.contents[0] = "STAGE" and p.contents[1] = currentStage) {
						do handlePhotoProposalFromChillingGuestAtStage(p);
					}
				}
				
				// meet photographer at bar and he proposes to take a pic
				match Photographer.name {
					if (p.contents[0] = "BAR" and p.contents[1] = currentBar) {
						do handlePhotoProposalFromPhotographerAtBar(p);
					} else if (p.contents[0] = "STAGE" and p.contents[1] = currentStage) {
						do handlePhotoProposalFromPhotographerAtStage(p);
					}
				}
				
				match Merchant.name {
					if (p.contents[0] = "BAR" and p.contents[1] = currentBar) {
						do handleMerchantProposalAtBar(p);
					} else if (p.contents[0] = "STAGE" and p.contents[1] = currentStage) {
						do handleMerchantProposalAtStage(p);
					}
				}
				
				
			}
		}
		
		loop reject over: reject_proposals {
			string senderType <- string(type_of(reject.sender));
			switch(senderType) {
				match ChillingGuest.name {
					if (reject.contents[0] = "STAGE" and reject.contents[1] = currentStage) {
							write "Time[" + time + "]: " + name + "'s offer to listen together is rejected by " + reject.sender;
							happiness <- happiness - 0.1;
					}
				}
			}
		}

		loop accept over: accept_proposals {
			string senderType <- string(type_of(accept.sender));
			switch(senderType) {
				match ChillingGuest.name {
					if (accept.contents[0] = "STAGE" and accept.contents[1] = currentStage) {
						write "Time[" + time + "]: " + name + "'s offer to listen together is accepted by " + accept.sender;
						happiness <- happiness + 0.1;
					}
				}
			}
		}

		
		loop agree over: agrees {
			string senderType <- string(type_of(agree.sender));
			switch(senderType) {
				match Bar.name {
					// if we are too drunk, happiness goes down...
					drunkness <- drunkness + 0.1;
					if (drunkness < 0.8) {
						happiness <- happiness + 0.1;	
					} else {
						happiness <- happiness - 0.1;
					}
				}
				match Photographer.name {
					if (agree.contents[0] = "BAR" and agree.contents[1] = currentBar) {
						// TODO
						happiness <- happiness + 0.05;
					} else if (agree.contents[0] = "STAGE" and agree.contents[1] = currentStage) {
						write "[Time: " + time + "] " + agree.sender + " will now take a picture of me." + name;  
						happiness <- happiness + 0.05;
					}
				}
			}
			
			string msgContent <- agree.contents[0];
		}
		
		loop refuse over: refuses {
			string senderType <- string(type_of(refuse.sender));
			switch(senderType) {
				match Photographer.name {
					if (refuse.contents[0] = "BAR" and refuse.contents[1] = currentBar) {
						// TODO
						happiness <- happiness - 0.05;
					} else if (refuse.contents[0] = "STAGE" and refuse.contents[1] = currentStage) {
						write "[Time: " + time + "] " + refuse.sender + " decided not to take a picture of me." + name;  
						happiness <- happiness - 0.05;
					}
				}
			}
		}
		
		loop inform over: informs {
			write "[Time: " + time + "] " + name + " receives informs " + informs;
			string senderType <- string(type_of(inform.sender));
			switch(senderType) {
				match DancingGuest.name {
					if(inform.contents[0] = "STAGE" and inform.contents[1] = currentStage) {
						// TODO should call security guard?
						string msg <- "I am leaving!";
						write "Time[" + time + "]: " + name + ": " +  msg + " " + inform.sender + " is following me!";
						happiness <- happiness - 0.2;
						do end_conversation message: inform contents: ["STAGE", currentStage, msg, cycle];
						do endTimeAtStage;
					}
				}
			}
						
			
		}
		
		do handleBeerSentFromFriend;
	}
	
	/*
	 * ACTIONS
	 */
	action aloneAtBar {
		if (shouldOrderABeerWhenAlone()) {
			do askBarForBeer(1);
		} else {
			write "[Time: " + time + "] " + name + " is just chilling at bar " + currentBar.name;
		}
	}
	
	// AT STAGE
	action aloneAtStage {
		if (shouldStartDancingAtStage()) {
			write "[Time: " + time + "] " + name + " starts dancing at stage " + currentStage.name;
			happiness <- happiness + 0.1;
		} else {
			write "[Time: " + time + "] " + name + " stands and enjoys the music at stage " + currentStage.name;
		}
	}
	
	action handleDancingGuestAtStage(message p) {
		message m <- p;
		if (shouldDanceWithDancingGuestAtStage(m.sender as DancingGuest)) {
			string msg <- "Sure, let's dance!";
			write "[Time: " + time + "] " + name + " is dancing with " + m.sender; 
			do accept_proposal message: m contents: ["STAGE", currentStage, msg, cycle];
			happiness <- happiness + 0.1;
		} else {
			write "[Time: " + time + "] " + name + " does not want to dance with " + m.sender; 
			do reject_proposal message: m contents: ["STAGE", currentStage, "No, please leave me alone.", cycle];
			happiness <- happiness - 0.1;
		}
	}
	
	action handleDancingGuestAtBar(message p) {
		message m <- p;
		if (shouldGoAwayFromBar(m.sender as DancingGuest)) {
			do refuse message: m contents: ["BAR", currentBar, "I do not want a beer from a you!"] ;
			do endTimeAtBar;
			write "[Time: " + time + "] " + name + " leaves bar because of the annoying Dancing guest " + m.sender;
			happiness <- happiness - 0.1;
		} else {
			do handleBeerProposalFromDancingGuestAtBar(m);	
		}
	}
	
	action meetPhotographerAtStage(Photographer p) {
		list<agent> initiators <- conversations collect (each.initiator);
		write "Time[" + time + "]: " + " initiator of conv. with photographer " + initiators;
		if ((!(initiators contains p)) and shouldAskPhotographerForAPhotoAtStage(p)) {
			write "Time[" + time + "]: " + name + " asks " + p.name + " to take a photo of them at stage " + currentStage.name;
			do start_conversation to: [p] protocol: "fipa-propose" performative: "query" 
				contents: ["STAGE", currentStage, PICTURE_QUERY, cycle];
		} else {
			write "Time[" + time + "]: " + name + " decides not to ask for a photo from " + p.name;
		}
	}
	
	action meetChillingGuestAtStage(ChillingGuest c) {
		list<agent> initiators <- conversations collect (each.initiator);
		write "Time[" + time + "]: " + " initiator of conv. with chilling guest " + initiators;
		if (!(initiators contains c) and shouldOfferToListenWithOtherGuest()) {
			write "Time[" + time + "]: " + name + " asks " + c.name + " to listen to music together at stage " + currentStage.name;
			do start_conversation to: [c] protocol: "fipa-propose" performative: "propose"
				contents: ["STAGE", currentStage, "Let's listen together!", cycle];
		}
	}
	
	
	// AT BAR
	action handleBeerProposalFromDancingGuestAtBar(message p) {
		if (acceptOfferredBeer()) {
			write "Time[" + time + "]: Accepting a beer from " + p.sender;
			do agree message: p contents: ["BAR", currentBar, "I will accept it now.", cycle] ;
			happiness <- happiness + 0.1;
		} else {
			write "Declining a beer from " + p.sender;
			do refuse message: p contents: ["BAR", currentBar, "I do not want a beer from a stranger"] ;
			happiness <- happiness - 0.1;
		}
	}

	action handlePhotoProposalFromPhotographerAtBar(message p) {
		if (acceptPhotoBeingTakenAtBar()) {
			write "Time[" + time + "]: Accepting a photo from " + p.sender;
			do accept_proposal message: p contents: ["BAR", currentBar, ACCEPT_PHOTO, cycle] ;
			happiness <- happiness + 0.1;
		} else {
			write "Time[" + time + "]: Declining a photo from " + p.sender;
			do reject_proposal message: p contents: ["BAR", currentBar, DECLINE_PHOTO] ;
			happiness <- happiness - 0.1;
		}
	}
	
	action handlePhotoProposalFromPhotographerAtStage(message p) {
		if (acceptPhotoBeingTakenAtStage()) {
			write "Time[" + time + "]: Accepting a photo from " + p.sender + "on stage " + currentStage.name;
			do accept_proposal message: p contents: ["STAGE", currentStage, ACCEPT_PHOTO, cycle] ;
			happiness <- happiness + 0.1;
		} else {
			write "Time[" + time + "]: Declining a photo from " + p.sender + "on stage " + currentStage.name;
			do reject_proposal message: p contents: ["STAGE", currentStage, DECLINE_PHOTO] ;
			happiness <- happiness - 0.1;
		}
	}
	
	action handlePhotoProposalFromChillingGuestAtStage(message p) {
		if(acceptToListenTogetherWithOtherChillingGuest()) {
			write "Time[" + time + "]: Accepting to listen together with " + p.sender + "on stage " + currentStage.name;
			do accept_proposal message: p contents: ["STAGE", currentStage, "OK!", cycle] ;
			happiness <- happiness + 0.1;
		} else {
			write "Time[" + time + "]: Declining to listen together with " + p.sender + "on stage " + currentStage.name;
			do reject_proposal message: p contents: ["STAGE", currentStage, "Sorry, I prefer to listen alone."] ;
			happiness <- happiness - 0.1;
		}
	}
	
	action handleMerchantProposalAtStage(message p) {
		write "Time[" + time + "]: " + name + " receives a proposal from merchant " + p.sender + " at stage " + currentStage.name;
		if (acceptToBuyFromMerchantAtStage(p.sender as Merchant)) {
			write "Time[" + time + "]: Accepting to buy from " + p.sender + " at stage " + currentStage.name;
			do accept_proposal message: p contents: ["STAGE", currentStage, BUY_MERCHANDISE, cycle] ;
			happiness <- happiness + 0.1;
		} else {
			write "Time[" + time + "]: Declining to buy from " + p.sender + " at stage " + currentStage.name;
			do reject_proposal message: p contents: ["STAGE", currentStage, DO_NOT_BUY_MERCHANDISE, cycle] ;
			happiness <- happiness - 0.1;
		}
	}
	
	action handleMerchantProposalAtBar(message p) {
		write "Time[" + time + "]: " + name + " receives a proposal from merchant " + p.sender + " at bar " + currentBar.name;
		if (acceptToBuyFromMerchantAtBar(p.sender as Merchant)) {
			write "Time[" + time + "]: Accepting to buy from " + p.sender + " at bar " + currentBar.name;
			do accept_proposal message: p contents: ["BAR", currentBar, BUY_MERCHANDISE, cycle] ;
			happiness <- happiness + 0.1;
		} else {
			write "Time[" + time + "]: Declining to buy from " + p.sender + " at bar " + currentBar.name;
			do reject_proposal message: p contents: ["BAR", currentBar, DO_NOT_BUY_MERCHANDISE, cycle] ;
			happiness <- happiness - 0.1;
		}
	}

	action askBarForBeer(int quantity) {
		write name + " is asking for a beer at bar " + currentBar.name;
		do start_conversation to: [currentBar] protocol: 'fipa-request' performative: 'request' contents: ["I would like beer.", quantity];
	}


	/*
	 * RULES
	 */
	 
	bool shouldDanceWithDancingGuestAtStage(DancingGuest dg) {
		return dg.loudness < 0.5 or nervous < 0.6;
	}
	 
	bool shouldGoAwayFromBar(DancingGuest dg) {
		write name + "in should go away from bar";
		return dg.loudness > 0.8 and positive < 0.7;
	} 
	
	bool shouldStartDancingAtStage {
		return positive > 0.5 and nervous < 0.8;
	}
	 	
	bool acceptOfferredBeer {
		return cautious < 0.7 and nervous < 0.8;
	}
	
	bool acceptPhotoBeingTakenAtBar {
		return positive > 0.6 and nervous < 0.5;
	}
	
	bool acceptPhotoBeingTakenAtStage {
		return nervous < 0.5 and positive > 0.5;
	}
	
	bool shouldAskPhotographerForAPhotoAtStage(Photographer p) {
		return cautious < 0.5 and positive > 0.6 and p.creative > 0.4;
	}
	
	bool shouldOrderABeerWhenAlone {
		bool shouldOrder <- (nervous > 0.5 or positive > 0.5) and currentBar != nil;
		return shouldOrder;
	}
	
	// Should offer to listen
	bool shouldOfferToListenWithOtherGuest {
		return positive > 0.3;
	}
	
	bool acceptToListenTogetherWithOtherChillingGuest {
		return positive > 0.3;
	}
	
	bool acceptToBuyFromMerchantAtStage(Merchant m) {
		return positive > 0.6 and cautious < 0.6 
			and m.convincing > 0.6 and m.promoting = true;
	}
	
	bool acceptToBuyFromMerchantAtBar(Merchant m) {
		return m.convincing > 0.6 and m.trustworthy > 0.6 and positive > 0.6;
	}
}

species Photographer parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/photographer.png");
	rgb myColor <- #pink;

	bool isWorking <- flip(0.5);
	float laziness <- rnd(0.0, 1.0) with_precision 2;
	float creative <- rnd(0.0, 1.0) with_precision 2;

	reflex isAtBarReflex when: isAtBar() {
		do handleInteractions;
	}

	reflex isAtBarToStartInteractionsReflex when: isAtBar() and timeAtBar mod 5 = 0 {
		do startInteractionsAtBar;
	}

	reflex isAtStageReflex when: isAtStage() {
		do handleInteractions;
	}

	reflex isAtStageToStartInteractionsReflex when: isAtStage() and timeAtStage mod 10 = 0 {
		do startInteractionsAtStage;
	}

	action startInteractionsAtBar {
		if (debug) {
			write "Time[" + time + "]: " + name + " starts interactions at bar.";
		}
		list<agent> agentsAtBar <- agents_overlapping(currentBar);
		remove self from: agentsAtBar;
		if (empty(agentsAtBar) or length(agentsAtBar) = 0) {
			do aloneAtBar;
		} else {
			loop agentAtBar over: agentsAtBar {
				string agentType <- string(type_of(agentAtBar));
				switch(agentType) {
					match DancingGuest.name {
						do meetDancingGuestAtBar(agentAtBar as DancingGuest);
					}
					match ChillingGuest.name {
						do meetChillingGuestAtBar(agentAtBar as ChillingGuest);
					}
					match Photographer.name {
						do meetPhotographerAtBar(agentAtBar as Photographer);
					}
					match Merchant.name {
						do meetMerchantAtBar(agentAtBar as Merchant);
					}
				}
			}
		}
	}

	action startInteractionsAtStage {
		write name + time + " start interactions at stage";
		list<agent> agentsAtStage <- agents_overlapping(currentStage);
		remove self from: agentsAtStage;
		if (empty(agentsAtStage) or length(agentsAtStage) = 0) {
			do takePictureOfStage;
		} else {
			loop agentAtStage over: agentsAtStage {
				string agentType <- string(type_of(agentAtStage));
				switch(agentType) {
					match DancingGuest.name {
						do meetDancingGuestAtStage(agentAtStage as DancingGuest);
					}
					match ChillingGuest.name {
						// TODO
						do meetChillingGuestAtStage(agentAtStage as ChillingGuest);
					}
					match Photographer.name {
						do meetPhotographerAtStage(agentAtStage as Photographer);
					}
				}
			}
		}
	}

	// MEET DANCING GUEST

	action meetDancingGuestAtBar(DancingGuest d) {
		list<agent> initiators <- conversations collect (each.initiator);
		write "Time[" + time + "]: " + " initiator of conv. with photographer " + initiators;
		if ((!(initiators contains d)) and shouldTakeAPhotoAtBar()) {
			write "Time[" + time + "]: " + name + " is taking a photo of " + d.name;
			do start_conversation to: [d] protocol: "fipa-propose" performative: "propose" 
				contents: ["BAR", currentBar, PHOTOGRAPHER_OFFERS_TO_TAKE_A_PHOTO];
		}
	}

	action meetDancingGuestAtStage(DancingGuest d) {
		list<agent> initiators <- conversations collect (each.initiator);
		write "Time[" + time + "]: " + " initiator of conv. with photographer " + initiators;
		if ((!(initiators contains d)) and shouldTakeAPhotoAtStage()) {
			write "Time[" + time + "]: " + name + " is taking a photo of " + d.name;
			do start_conversation to: [d] protocol: "fipa-propose" performative: "propose" 
				contents: ["STAGE", currentStage, PHOTOGRAPHER_OFFERS_TO_TAKE_A_PHOTO];
		}
	}

	// MEET CHILLING GUEST
	
	action meetChillingGuestAtBar(ChillingGuest g) {
		list<agent> initiators <- conversations collect (each.initiator);
		write "Time[" + time + "]: " + " initiator of conv. with photographer " + initiators;
		if ((!(initiators contains g)) and shouldTakeAPhotoAtBar()) {
			write "Time[" + time + "]: " + name + " is taking a photo of " + g.name;
			do start_conversation to: [g] protocol: "fipa-propose" performative: "propose" 
				contents: ["BAR", currentBar, PHOTOGRAPHER_OFFERS_TO_TAKE_A_PHOTO, cycle];
		} else {
			write "Time[" + time + "]: " + name + " decides not to offer to take a photo of " + g.name;
		}
	}
	
	action meetChillingGuestAtStage(ChillingGuest g) {
		list<agent> initiators <- conversations collect (each.initiator);
		write "Time[" + time + "]: " + " initiator of conv. with photographer " + initiators;
		if ((!(initiators contains g)) and shouldTakeAPhotoOfChillingGuestAtStage()) {
			write "Time[" + time + "]: " + name + " is taking a photo of " + g.name + " at stage " + currentStage.name;
			do start_conversation to: [g] protocol: "fipa-propose" performative: "propose" 
				contents: ["STAGE", currentStage, PHOTOGRAPHER_OFFERS_TO_TAKE_A_PHOTO, cycle];
		} else {
			write "Time[" + time + "]: " + name + " decides not to offer to take a photo of " + g.name;
		}
	}
	
	// MEET PHOTOGRAPHER

	action meetPhotographerAtBar(Photographer p) {
		if (shouldHaveABeerAtBar()) {
			do offerBeerToColleague(p);
		} else {
			do sayHiToColleagueAtBar(p);
		}
	}

	action meetPhotographerAtStage(Photographer p) {
		do sayHiToColleagueAtStage(p);
	}

	// MEET MERCHANT
	
	action meetMerchantAtBar(Merchant m) {
		if (shouldTryToBuyFromMerchantAtABar()) {
			write "Time[" + time + "]: " + name + " approaches merchant " + m;
			do start_conversation to: [m] protocol: 'fipa-contract-net' performative: 'cfp' contents: ["BAR", currentBar, ASK_MERCHANT_FOR_OFFER];
		} else {
			write "Time[" + time + "]: " + name + " decides not to approach merchant " + m;
		}
	}

	action handleInteractions {
		if (!(empty(queries))) {
			loop q over: queries {
				string senderType <- string(type_of(q.sender));
				switch senderType {
					match DancingGuest.name {
						if (q.contents[0] = "BAR" and q.contents[1] = currentBar and q.contents[2] = PICTURE_QUERY) {
							do handleDancingGuestAtBar(q);
						} else if(q.contents[0] = "STAGE" and q.contents[1] = currentStage and q.contents[2] = PICTURE_QUERY) {
							do handleDancingGuestAtStage(q);
						}
					}
					match ChillingGuest.name {
						if (q.contents[0] = "BAR" and q.contents[1] = currentBar and q.contents[2] = PICTURE_QUERY) {
							// TODO
						} else if(q.contents[0] = "STAGE" and q.contents[1] = currentStage and q.contents[2] = PICTURE_QUERY) {
							do handleChillingGuestAtStage(q);
						}
					}
				}
			}
		}

		loop reject over: reject_proposals {
			string senderType <- string(type_of(reject.sender));
			switch(senderType) {
				match DancingGuest.name {
					if (reject.contents[0] = "BAR" and reject.contents[1] = currentBar and reject.contents[2] = DECLINE_PHOTO) {
							write "Time[" + time + "]: " + name + "'s offer is rejected by " + reject.sender;
							happiness <- happiness - 0.1;
					} else if (reject.contents[0] = "STAGE" and reject.contents[1] = currentStage and reject.contents[2] = DECLINE_PHOTO) {
							write "Time[" + time + "]: " + name + "'s offer is rejected by " + reject.sender;
							happiness <- happiness - 0.1;
					}
				}
				match ChillingGuest.name {
					if (reject.contents[0] = "BAR" and reject.contents[1] = currentBar and reject.contents[2] = DECLINE_PHOTO) {
							write "Time[" + time + "]: " + name + "'s offer is rejected by " + reject.sender;
							happiness <- happiness - 0.1;
					} else if (reject.contents[0] = "STAGE" and reject.contents[1] = currentStage and reject.contents[2] = DECLINE_PHOTO) {
							write "Time[" + time + "]: " + name + "'s offer is rejected by " + reject.sender;
							happiness <- happiness - 0.1;
					}
				}
				match Photographer.name {
					if (reject.contents[0] = "BAR" and reject.contents[1] = currentBar and reject.contents[2] = DECLINE_DRINK) {
						write "Time[" + time + "]: " + name + "'s offer is declined by " + reject.sender;
						happiness <- happiness - 0.1;
					}
				}
			}
		}

		loop accept over: accept_proposals {
			string senderType <- string(type_of(accept.sender));
			switch(senderType) {
				match DancingGuest.name {
					if (accept.contents[0] = "BAR" and accept.contents[1] = currentBar and accept.contents[2] = ACCEPT_PHOTO) {
						write "Time[" + time + "]: " + name + "'s offer is accepted by " + accept.sender;
						happiness <- happiness + 0.1;
					} else if (accept.contents[0] = "STAGE" and accept.contents[1] = currentStage and accept.contents[2] = ACCEPT_PHOTO) {
						write "Time[" + time + "]: " + name + "'s offer is accepted by " + accept.sender;
						happiness <- happiness + 0.1;
					}
				}
				match ChillingGuest.name {
					if (accept.contents[0] = "BAR" and accept.contents[1] = currentBar and accept.contents[2] = ACCEPT_PHOTO) {
						write "Time[" + time + "]: " + name + "'s offer is accepted by " + accept.sender;
						happiness <- happiness + 0.1;
					} else if (accept.contents[0] = "STAGE" and accept.contents[1] = currentStage and accept.contents[2] = ACCEPT_PHOTO) {
						write "Time[" + time + "]: " + name + "'s offer is accepted by " + accept.sender;
						happiness <- happiness + 0.1;
					}
				}
				match Photographer.name {
					if (accept.contents[0] = "BAR" and accept.contents[1] = currentBar and accept.contents[2] = ACCEPT_DRINK) {
						write "Time[" + time + "]: " + name + "'s offer is accepted by " + accept.sender;
						happiness <- happiness + 0.1;
						do askBarForBeer(1);
					}
				}
			}
		}

		loop inform over: informs {
			string senderType <- string(type_of(inform.sender));
			switch(senderType) {
				match Photographer.name {
					if (inform.contents[0] = "STAGE" and inform.contents[1] = currentStage and inform.contents[2] = SAY_HI_TO_COLLEAGUE) {
						write "Time[" + time + "]: " + name + " says hi to " + inform.sender;
						do end_conversation message: inform contents: ["Hello."] ;
					} else if (inform.contents[0] = "BAR" and inform.contents[1] = currentBar and inform.contents[2] = SAY_HI_TO_COLLEAGUE) {
						write "Time[" + time + "]: " + name + " says hi to " + inform.sender;
						do end_conversation message: inform contents: ["Nice to see you at the bar."] ;
					}
				}
			}
		}

		loop agree over: agrees {
			string senderType <- string(type_of(agree.sender));
			switch(senderType) {
				match Bar.name {
					// bar has beer
					do drinkBeer(agree.contents[1] as int);
				}
			}
			string msgContent <- agree.contents[0];
		}

		loop refuse over: refuses {
			string senderType <- string(type_of(refuse.sender));
			switch(senderType) {
				match Merchant.name {
					if (refuse.contents[0] = "BAR" and refuse.contents[1] = currentBar) {
						write "Time[" + time + "]: " + name + " receives a refuse from merchant " + refuse.sender;
						happiness <- happiness - 0.05;
					}
				}
				match Bar.name {
					// Bar has no more beer
					happiness <- happiness - 0.1 * (refuse.contents[1] as int);
				}
			}
		}

		loop propose over: proposes {
			string senderType <- string(type_of(propose.sender));
			switch(senderType) {
				match Photographer.name {
					if (propose.contents[0] = "BAR" and propose.contents[1] = currentBar and propose.contents[2] = DRINK_OFFER) {
						if (shouldHaveABeerAtBar()) {
							write "Time[" + time + "]: " + name + " accepting proposal to drink at " + currentBar.name;
							do accept_proposal message: propose contents: ["BAR", currentBar, ACCEPT_DRINK];
							do askBarForBeer(1);
						} else {
							do reject_proposal message: propose contents: ["BAR", currentBar, DECLINE_DRINK];
						}
					}
				}
				match Merchant.name {
					if (propose.contents[0] = "BAR" and propose.contents[1] = currentBar and propose.contents[2] = MERCHANT_MAKES_AN_OFFER) {
						write "Time[" + time + "]: " + name + " accepting merchant's offer for purchase " + currentBar.name;
						happiness <- happiness + 0.1;
						do accept_proposal message: propose contents: ["BAR", currentBar, BUY_MERCHANDISE];
					}		
				}
			}
		}
	}
	
	/*
	 * ACTIONS
	 */

	action handleDancingGuestAtBar(message p) {
		if (acceptToTakeAPicture()) {
			write "Time[" + time + "]: Accepting to take a picture of " + p.sender;
			do agree message: p contents: ["BAR", currentBar, "I will accept it now."] ;
			happiness <- happiness + 0.1;
		} else {
			write "Time[" + time + "]: Declining a picture from " + p.sender;
			do refuse message: p contents: ["BAR", currentBar, "Leave me alone"] ;
			happiness <- happiness - 0.1;
		}
	}

	action handleDancingGuestAtStage(message p) {
		if (acceptToTakeAPicture()) {
			write "Time[" + time + "]: Accepting to take a picture of " + p.sender;
			do agree message: p contents: ["STAGE", currentStage, "I will accept it now."] ;
			happiness <- happiness + 0.1;
		} else {
			write "Time[" + time + "]: Declining a picture from " + p.sender;
			do refuse message: p contents: ["STAGE", currentStage, "Leave me alone"] ;
			happiness <- happiness - 0.1;
		}
	}

	action handleChillingGuestAtStage(message p) {
		if (acceptToTakeAPictureOfChillingGuestAtStage(p.sender)) {
			write "Time[" + time + "]: Accepting to take a picture of " + p.sender;
			do agree message: p contents: ["STAGE", currentStage, "I will accept it now."] ;
			happiness <- happiness + 0.1;
		} else {
			write "Time[" + time + "]: Declining a picture from " + p.sender;
			do refuse message: p contents: ["STAGE", currentStage, "Leave me alone"] ;
			happiness <- happiness - 0.1;
		}
	}
	
	action takePictureOfStage {
		do start_conversation to: [currentStage] protocol: "no-protocol" performative: "inform" contents: ["STAGE", currentStage, TAKE_PICTURE_OF_STAGE];
	}

	action sayHiToColleagueAtBar(Photographer p) {
		do start_conversation to: [p] protocol: "no-protocol" performative: "inform" contents: ["BAR", currentBar, SAY_HI_TO_COLLEAGUE];
	}

	action sayHiToColleagueAtStage(Photographer p) {
		do start_conversation to: [p] protocol: "no-protocol" performative: "inform" contents: ["STAGE", currentStage, SAY_HI_TO_COLLEAGUE];
	}

	action aloneAtBar {
		if (shouldHaveABeerAtBar()) {
			do askBarForBeer(1);
		}
	}

	action askBarForBeer(int quantity) {
		write "Time[" + time + "]: " + name + " is asking for a beer at bar " + currentBar.name;
		do start_conversation to: [currentBar] protocol: 'fipa-request' performative: 'request' contents: ["I would like beer.", quantity];
	}

	action offerBeerToColleague(Photographer p) {
		list<agent> initiators <- conversations collect (each.initiator);
		if (!(initiators contains p)) {
			write "Time[" + time + "]: " + name + " starts drinking with " + p.name;
			do start_conversation to: [p] protocol: "fipa-propose" performative: "propose" contents: ["BAR", currentBar, DRINK_OFFER];
		}
	}

	/*
	 * RULES
	 */

	bool acceptToTakeAPicture {
		return flip(0.7);
	}
	
	bool acceptToTakeAPictureOfChillingGuestAtStage(ChillingGuest g) {
		return g.nervous < 0.6 and laziness < 0.8;
	}

	bool shouldTakeAPhotoAtBar {
		return isWorking and laziness < 0.8;
	}

	bool shouldTakeAPhotoAtStage {
		return creative > 0.2 and laziness < 0.7;
	}
	
	bool shouldTakeAPhotoOfChillingGuestAtStage {
		return creative > 0.4 and laziness < 0.8;
	}

	bool shouldHaveABeerAtBar {
		return !isWorking;
	}
	
	bool shouldTryToBuyFromMerchantAtABar {
		return !isWorking and creative > 0.5 and laziness < 0.4;
	}
}

species Merchant parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/merchant.jpg");
	rgb myColor <- #aquamarine;
	
	float trustworthy <- rnd(0.0, 1.0) with_precision 2;
	float convincing <- rnd(0.0, 1.0) with_precision 2;
	bool promoting <- flip(0.5);
	
	reflex isAtBarReflex when: isAtBar() {
		do handleInteractions;
	}
	
	reflex isAtBarToStartInteractionsReflex when: isAtBar() and timeAtBar mod 5 = 0 {
		do startInteractionsAtBar;
	}
	
	reflex isAtStageToStartInteractionsReflex when: isAtStage() and timeAtStage mod 5 = 0 {
		do startInteractionsAtStage;
	}
	
	action startInteractionsAtBar {
		write name + " start interactions at bar " + time;
		list<agent> agentsAtBar <- agents_overlapping(currentBar);
		remove self from: agentsAtBar;
		if(empty(agentsAtBar) or length(agentsAtBar) = 0) {
			do aloneAtBar;
		} else {
			loop agentAtBar over: agentsAtBar {
				string agentType <- string(type_of(agentAtBar));
				switch(agentType) {
					match DancingGuest.name {
						do meetDancingGuestAtBar(agentAtBar as DancingGuest);
					}
					match ChillingGuest.name {
						do meetChillingGuestAtBar(agentAtBar as ChillingGuest);
					}
					match Merchant.name {
						do sayHiToColleagueAtBar(agentAtBar as Merchant);
					}
				}
			}
		}
	}
	
	action startInteractionsAtStage {
		write name + "start interactions at stage " + time;
		list<agent> agentsAtStage <- agents_overlapping(currentStage);
		remove self from: agentsAtStage;
		if(empty(agentsAtStage) or length(agentsAtStage) = 0) {
			do aloneAtStage;
		} else {
			loop agentAtStage over: agentsAtStage {
				string agentType <- string(type_of(agentAtStage));
				switch(agentType) {
					match DancingGuest.name {
						do meetDancingGuestAtStage(agentAtStage as DancingGuest);
					}
					match ChillingGuest.name {
						do meetChillingGuestAtStage(agentAtStage as ChillingGuest);
					}
					match Merchant.name {
						do sayHiToColleagueAtStage(agentAtStage as Merchant);
					}
				}
			}
		}
	}
	
	action handleInteractions {
		loop cfp over: cfps {
			string senderType <- string(type_of(cfp.sender));
	        switch(senderType) {
				match DancingGuest.name {
	            	do handleDancingGuestAtBar(cfp);
	            }
	            match Photographer.name {
	            	do handlePhotographerAtBar(cfp);
	            }
	       	}
	    }
		
		loop reject over: reject_proposals {
			string senderType <- string(type_of(reject.sender));
			switch(senderType) {
				match DancingGuest.name {
					if (reject.contents[0] = "BAR" and reject.contents[1] = currentBar and reject.contents[2] = MERCHANT_NOT_TRUSTWORTHY) {
						write "Time[" + time + "]: " + name + "'s offer is rejected by " + reject.sender;
						happiness <- happiness - 0.1;
					} else if (reject.contents[0] = "STAGE" and reject.contents[1] = currentStage and reject.contents[2] = DO_NOT_BUY_MERCHANDISE) {
						write "Time[" + time + "]: " + name + "'s offer is rejected by " + reject.sender + " at stage " + currentStage;
						happiness <- happiness - 0.1;
					}
				}
				match ChillingGuest.name {
					if (reject.contents[0] = "BAR" and reject.contents[1] = currentBar and reject.contents[2] = DO_NOT_BUY_MERCHANDISE) {
						write "Time[" + time + "]: " + name + "'s offer is rejected by " + reject.sender;
						happiness <- happiness - 0.1;
					} else if (reject.contents[0] = "STAGE" and reject.contents[1] = currentStage and reject.contents[2] = DO_NOT_BUY_MERCHANDISE) {
						write "Time[" + time + "]: " + name + "'s offer is rejected by " + reject.sender + " at stage " + currentStage;
						happiness <- happiness - 0.1;
					}
				}
			}
		}
	
		loop accept over: accept_proposals {
			string senderType <- string(type_of(accept.sender));
			switch(senderType) {
				match DancingGuest.name {
					if (accept.contents[0] = "BAR" and accept.contents[1] = currentBar and accept.contents[2] = BUY_MERCHANDISE) {
						write "Time[" + time + "]: " + name + "'s offer is accepted by " + accept.sender;
						happiness <- happiness + 0.1;	
					} else if (accept.contents[0] = "STAGE" and accept.contents[1] = currentStage and accept.contents[2] = BUY_MERCHANDISE) {
						write "Time[" + time + "]: " + name + "'s offer is accepted by " + accept.sender + " at stage " + currentStage;
						happiness <- happiness + 0.1;
					}
				}
				match ChillingGuest.name {
					if (accept.contents[0] = "BAR" and accept.contents[1] = currentBar and accept.contents[2] = BUY_MERCHANDISE) {
						write "Time[" + time + "]: " + name + "'s offer is accepted by " + accept.sender;
						happiness <- happiness + 0.1;	
					} else if (accept.contents[0] = "STAGE" and accept.contents[1] = currentStage and accept.contents[2] = BUY_MERCHANDISE) {
						write "Time[" + time + "]: " + name + "'s offer is accepted by " + accept.sender + " at stage " + currentStage;
						happiness <- happiness + 0.1;
					}
				}
			}
		}
		
		loop inform over: informs {
			string senderType <- string(type_of(inform.sender));
			switch(senderType) {
				match Photographer.name {
					if (inform.contents[0] = "STAGE" and inform.contents[1] = currentStage and inform.contents[2] = SAY_HI_TO_MERCHANT) {
						write "Time[" + time + "]: " + name + " says hi to " + inform.sender;
						do end_conversation message: inform contents: ["STAGE", currentStage,"Hello."] ;
					} else if (inform.contents[0] = "BAR" and inform.contents[1] = currentBar and inform.contents[2] = SAY_HI_TO_MERCHANT) {
						write "Time[" + time + "]: " + name + " says hi to " + inform.sender;
						do end_conversation message: inform contents: ["BAR", currentBar, "Nice to see you at the bar."] ;
					}
				}
			}
		}
	}
	
	action meetDancingGuestAtBar(DancingGuest d) {
		list<agent> initiators <- conversations collect (each.initiator);
		if ((!(initiators contains d)) and shouldAppraochDancingGuestToSellAtBar(d)) {
			write "Time[" + time + "]: " + name + " asks " + d.name + " to if they want to buy something at bar " + currentBar.name;
			do start_conversation to: [d] protocol: "fipa-propose" performative: "propose" 
				contents: ["BAR", currentBar, MERCHANT_MAKES_AN_OFFER, cycle];
		} else {
			write "Time[" + time + "]: " + name + " decides not to sell merchandise " + d.name;
		}
	}
	
	action meetDancingGuestAtStage(DancingGuest d) {
		list<agent> initiators <- conversations collect (each.initiator);
		if ((!(initiators contains d)) and shouldApproachDancingGuestToSell(d)) {
			write "Time[" + time + "]: " + name + " asks " + d.name + " to if they want to buy something at stage " + currentStage.name;
			do start_conversation to: [d] protocol: "fipa-propose" performative: "propose" 
				contents: ["STAGE", currentStage, MERCHANT_MAKES_AN_OFFER, cycle];
		} else {
			write "Time[" + time + "]: " + name + " decides not to sell merchandise " + d.name;
		}	
	}
	
	action handleDancingGuestAtBar(message cfp) {
		if (cfp.contents[0] = "BAR" and cfp.contents[1] = currentBar and cfp.contents[2] = ASK_MERCHANT_FOR_OFFER) {
        	bool isWorking <- flip(MERCHANT_WORKING_AT_BAR);
            if (isWorking) {
            	write "Time[" + time + "]: " + name + " makes a proposal " + cfp.sender;
                do propose message: cfp contents: ["BAR", currentBar, MERCHANT_MAKES_AN_OFFER];
            } else {
            	write "Time[" + time + "]: " + name + " refuses offer from " + cfp.sender;
                do refuse message: cfp contents: ["BAR", currentBar, MERCHANT_IS_NOT_WORKING];
            }
        }
	}
	
	action meetChillingGuestAtStage(ChillingGuest g) {
		list<agent> initiators <- conversations collect (each.initiator);
		write "Time[" + time + "]: " + " initiator of conv. with photographer " + initiators;
		if ((!(initiators contains g)) and shouldApproachChillingGuestToSellAtStage(g)) {
			write "Time[" + time + "]: " + name + " asks " + g.name + " to if they want to buy something at stage " + currentStage.name;
			do start_conversation to: [g] protocol: "fipa-propose" performative: "propose" 
				contents: ["STAGE", currentStage, MERCHANT_MAKES_AN_OFFER, cycle];
		} else {
			write "Time[" + time + "]: " + name + " decides not to sell merchandise " + g.name;
		}
	}
	
	action meetChillingGuestAtBar(ChillingGuest g) {
		list<agent> initiators <- conversations collect (each.initiator);
		if ((!(initiators contains g)) and shouldApproachChillingGuestToSellAtBar(g)) {
			write "Time[" + time + "]: " + name + " asks " + g.name + " to if they want to buy something at bar " + currentBar.name;
			do start_conversation to: [g] protocol: "fipa-propose" performative: "propose" 
				contents: ["BAR", currentBar, MERCHANT_MAKES_AN_OFFER, cycle];
		} else {
			write "Time[" + time + "]: " + name + " decides not to sell merchandise to " + g.name;
		}
	}

	action handlePhotographerAtBar(message cfp) {
		if (cfp.contents[0] = "BAR" and cfp.contents[1] = currentBar and cfp.contents[2] = ASK_MERCHANT_FOR_OFFER) {
        	bool isWorking <- flip(MERCHANT_WORKING_AT_BAR);
            if (isWorking) {
            	write "Time[" + time + "]: " + name + " makes a proposal " + cfp.sender;
                do propose message: cfp contents: ["BAR", currentBar, MERCHANT_MAKES_AN_OFFER];
            } else {
            	write "Time[" + time + "]: " + name + " refuses offer from " + cfp.sender;
                do refuse message: cfp contents: ["BAR", currentBar, MERCHANT_IS_NOT_WORKING];
            }
        }
	}
	
	action sayHiToColleagueAtBar(Merchant m) {
		write "Time[" + time + "]: " + name + " greets a colleague " + m.name + " at bar " + currentBar.name;
		do start_conversation to: [m] protocol: "no-protocol" performative: "inform" contents: ["BAR", currentBar, SAY_HI_TO_MERCHANT];
	}

	action sayHiToColleagueAtStage(Merchant m) {
		write "Time[" + time + "]: " + name + " greets a colleague " + m.name + " at stage " + currentStage.name;
		do start_conversation to: [m] protocol: "no-protocol" performative: "inform" contents: ["STAGE", currentStage, SAY_HI_TO_MERCHANT];
	}
	
	action aloneAtBar {
		write "Time[" + time + "]: " + name + " chills at bar " + currentBar.name;
	}
	
	action aloneAtStage {
		write "Time[" + time + "]: " + name + " waiting for people at stage " + currentStage.name;
	}
	
	/*
	 * RULES
	 */
	bool shouldApproachDancingGuestToSell(DancingGuest d) {
		return convincing > 0.6 and d.loudness < 0.8;
	}
	
	bool shouldAppraochDancingGuestToSellAtBar(DancingGuest d) {
		return d.drunkness < 0.7 and d.loudness < 0.7 and convincing > 0.6;
	}
	 
	bool shouldApproachChillingGuestToSellAtStage(ChillingGuest g) {
		return trustworthy > 0.6 and convincing > 0.6 and g.nervous < 0.4;
	}
	
	bool shouldApproachChillingGuestToSellAtBar(ChillingGuest g) {
		return g.positive > 0.4 and g.nervous < 0.5 and trustworthy > 0.5;
	}
}

species SecurityGuard skills: [moving, fipa] {
	image_file my_icon <- image_file("../includes/data/security-guard.png");
	
	init {
		speed <- 10.0 #km/#h;
	}
	
	rgb guardColor <- #black;
	Guest capturedGuest <- nil;
	Prison prison <- Prison closest_to(location);
	
	reflex wait when: capturedGuest = nil {
		do wander;
		do handleLoudAndNoisyGuest;
	}
	
	reflex capture when: capturedGuest != nil {
		write self.name + " capturing target " + capturedGuest.name;
		do goto target: capturedGuest;
		
		if (capturedGuest.isBad() and self distance_to(capturedGuest) < 3) {
			do start_conversation to: [capturedGuest] protocol: 'fipa-request' performative: 'request' contents: [SECURITY_GUARD_CAUGHT_YOU];
			capturedGuest <- nil;
		}
	}

	action captureBadGuest(Guest badGuest) {
		if (self != nil and badGuest != nil) {
			 write self.name + ": here at capture bad guest action of guard for guest: " + badGuest.name;
			capturedGuest <- badGuest;
		}
	}
	
	action handleLoudAndNoisyGuest {
		if (!empty(informs)) {
			message msg <- informs[0];
			write self.name + ": entering capture bad guest action: " + informs[0].sender;
			capturedGuest <- informs[0].sender;
			do end_conversation message: msg contents: [SECURITY_GUARD_HEADING_TO_YOU];
		}
	}
	
	aspect info {
		draw cube(5) at: location color: guardColor;
		draw string(capturedGuest.name) size: 3 color: #black;
	}

	
	aspect icon {
		draw my_icon size: 4;
	}
}

species Stage skills: [fipa] {
	image_file my_icon <- image_file("../includes/data/stage.png");
	
	rgb stageColor <- #green;
	string musicType <- musicTypes[rnd(2)];
	
	aspect info {
		draw square(5) at: location color: #transparent border: stageColor;
		draw string("Music type: " + musicType) size: 3 color: stageColor;
	}
	
	aspect icon {
		draw my_icon size: 5;
	}

	reflex handleInteractions {
		loop inform over: informs {
			string senderType <- string(type_of(inform.sender));
			switch(senderType) {
				match Photographer.name {
					if (inform.contents[0] = "STAGE" and inform.contents[1] = self and inform.contents[2] = TAKE_PICTURE_OF_STAGE) {
						write "Time[" + time + "]: " + name + " will have a picture taken by " + inform.sender;
						do end_conversation message: inform contents: ["Awesome."] ;
					}
				}
			}
		}
	}
}

species Bar skills: [fipa] {
	
	image_file my_icon <- image_file("../includes/data/bar.png");
	
	rgb barColor <- #blue;
	int beer <- 20 min: 0;
	
	aspect info {
		draw square(5) at: location color: #transparent border: barColor;
		draw string("Beers: " + beer) size: 3 color: barColor;
	}
	
	aspect icon {
		draw my_icon size: 5;
	}
	
	reflex reloadBeer when: cycle mod 500 = 0 {
		beer <- beer + 20;
	}
	
	reflex reply_beer_requests when: (!empty(requests)) {
		loop r over: requests {
			agent friendAtBar <- nil;
			if ((length(list(r.contents))) > 2) {
				friendAtBar <- r.contents[2] as agent;
			}
			int requestedBeer <- r.contents[1] as int;
			
			if (beer - requestedBeer >= 0) {
				write "Time[" + time +"]: " + name + " will provide " + requestedBeer + " beer(s).";
				do agree message: (r) contents: [BEER_IN_STOCK, requestedBeer];
				beer <- beer - (r.contents[1] as int);
				if (friendAtBar != nil) {
					do start_conversation to: [friendAtBar] protocol: 'no-protocol' performative: 'inform' contents: [BEER_IN_STOCK, requestedBeer];
				} 
			} else {
				write "Time[" + time +"]: " + name + " has no more beers.";
				do refuse message: (r) contents: [NO_MORE_BEER, requestedBeer] ;
				if (friendAtBar != nil) {
					do start_conversation to: [friendAtBar] protocol: 'no-protocol' performative: 'inform' contents: [NO_MORE_BEER, requestedBeer];
				} 
			}
		}
	}
}

species Prison {
	rgb myColor <- #grey;
	image_file my_icon <- image_file("../includes/data/prison.png");
	
	init {
		location <- prisonLocation;
	}
	
	aspect info {
		draw square(5) at: location color: myColor;
	}
	
	aspect icon {
		draw my_icon size: 5;
	}
}

species Toilet skills: [fipa] {
	rgb myColor <- #gold;
	image_file my_icon <- image_file("../includes/data/toilet.jpg");

	point toiletEntrance;
	init {
		location <- {rnd(30.0, 80.0), rnd(30.0, 80.0)};
		toiletEntrance <- {(self.location.x - 4) with_precision 2, self.location.y};
	}

	list<Guest> queue <- [];
	Guest guestInside <- nil;
	int timePerGuestInToilet <- TIME_PER_GUEST_IN_TOILET;
	
	reflex reply_requests_to_use_toilet when: (!empty(requests)) {
		loop r over: requests {
			if (guestInside = nil) {
				do agree message: (r) contents: [TOILET_IS_FREE];
				guestInside <- r.sender;
				write "Time[" + time + "]: Toilet is free for guest " + guestInside;
			} else {
				do refuse message: (r) contents: [TOILET_IS_TAKEN];
				write "Time[" + time + "]: Toilet is taken for guest " + r.sender;
				add r.sender to: queue;
				write "Current queue state: " + queue;
			}
			string msg <- r.contents[0];
		}
	}

	reflex updateToiletState when: guestInside != nil {
		timePerGuestInToilet <- timePerGuestInToilet - 1;
		if (timePerGuestInToilet = 0) {
			write "Time[" + time + "]: Current queue state is: " + queue;
			do start_conversation to: [guestInside] protocol: "no-protocol" performative: "inform" contents:[GET_OUT_OF_TOILET];
			if (!empty(queue) and length(queue) >= 1) {
				guestInside <- queue[0];
				write "Time[" + time + "]: New guest inside: " + guestInside;
				guestInside.target <- location;
				do moveQueueForward;
			} else {
				guestInside <- nil;
				queue <- [];
			}
			timePerGuestInToilet <- TIME_PER_GUEST_IN_TOILET;
		}
	}
	
	action moveQueueForward {
		loop i from: 0 to: length(queue) - 1 {
			if (i < length(queue) - 1) {
				queue[i] <- queue[i + 1];
				do start_conversation to: [queue[i]] protocol: "no-protocol" performative: "inform" contents:[QUEUE_MOVING_FORWARD];
			}
		}
		int lastIndexOfQueue <- length(queue) - 1;
		remove queue[lastIndexOfQueue] from: queue;
	}

	aspect info {
		draw square(5) at: location color: myColor;
	}
	
	aspect icon {
		draw my_icon size: 5;
	}
}

experiment fest_experiment type: gui {
//	parameter "Initial number of bars: " var: barsNum category: "Fun places at the festival" ;
	output {
		display main_display {
            species Guest aspect: icon;
			species DancingGuest aspect: icon;
			species ChillingGuest aspect: icon;
			species Bar aspect: icon;
			species Stage aspect: icon;
			species Photographer aspect: icon;
			species Prison aspect: icon;
			species SecurityGuard aspect: icon;
			species Merchant aspect: icon;
			species Toilet aspect: icon;
        }

        display info_display {
            species Guest aspect: info;
			species DancingGuest aspect: info;
			species ChillingGuest aspect: info;
			species Bar aspect: info;
			species Stage aspect: info;
			species Photographer aspect: info;
			species Prison aspect: info;
			species SecurityGuard aspect: info;
			species Merchant aspect: info;
			species Toilet aspect: info;
        }
		
		display Happiness_information refresh: every(5#cycles) {
        	chart "Happiness vs waiting time" type: series style: spline {
        		data "happiness" value: happinessLevel color: #green marker: false;
        		data "waiting time" value: globalWaitingTime color: #red marker: false;
        	}
		}
    	monitor "Happiness: " value: happinessLevel;
    	monitor "Waiting time: " value: globalWaitingTime;
	}
	
	
}

