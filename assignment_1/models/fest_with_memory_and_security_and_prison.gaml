/***
* Name: fest
* Author: Milko and Viktoriya
* Description: 
* Tags: Tag1, Tag2, TagN
***/

// TODO change target point location with agent reference 

model fest

/* Insert your model definition here */

global {
	int numberOfGuests <- 10;
	
	point informationCenterLocation <- {50.0, 50.0};
	point prisonLocation <- {100.0, 100.0};
	
	float hungerThreshold <- 20.0;
	float thirstThreshold <- 20.0;

	
	init {
		create Guest number: numberOfGuests;
		create InformationCenter number: 1;
		create FoodStore number: 2;
		create DrinksStore number: 2;
		create SecurityGuard number: 1;
		create Prison number: 1;
	}
}

species SecurityGuard skills: [moving] {
	init {
		speed <- 10.0 #km/#h;
	}
	
	rgb guardColor <- #black;
	point targetPoint <- nil;
	Guest capturedGuest <- nil;
	Prison prison <- Prison closest_to(location);
	
	reflex wait when: targetPoint = nil {
		InformationCenter infoCenter <- InformationCenter closest_to(location);
		list<Guest> guestList <- Guest at_distance(15);
		Guest badGuest <- guestList first_with (each.isBad() = true);
		if (badGuest != nil) {
			write self.name + ": entering capture bad guest action: " + badGuest.name;
			do captureBadGuest(badGuest);
		}
	}
	
	reflex capture when: capturedGuest != nil {
		write self.name + " capturing target " + capturedGuest.name;
		do goto target: capturedGuest;
		
		if (capturedGuest.isBad() and self distance_to(capturedGuest) < 3) {
			ask capturedGuest {
				// escort to prison
				write "bringing target to prison " + self.name;
				status ("Now " + self.name + " will stay in prison! - said " + myself.name) color: #yellow;
				self.targetPoint <- prisonLocation;
				self.timeInPrison <- 10;
				myself.targetPoint <- prisonLocation;
//				do goto target: myself.prison;
			}
		}
	}

	action captureBadGuest(Guest badGuest) {
		if (self != nil and badGuest != nil) {
			 write self.name + ": here at capture bad guest action of guard for guest: " + badGuest.name;
			capturedGuest <- badGuest;
		}
	}
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
		if (location = targetPoint) {
			targetPoint <- nil;
		}
	}
	
	reflex getOutOfPrison when: location = prisonLocation {
		write self.name + " in prison and should go out to capture other bad guys";
		capturedGuest <- nil;
		targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
	}
	
	aspect default {
		draw cube(5) at: location color: guardColor;
	}
}

/**
 * Guest Species
 */
species Guest skills: [moving] {
	init {
		speed <- 5.0 #km/#h;
	}
	
	rgb myColor <- #red;
	float thirst <- 0.0;
	float hunger <- 0.0;
	bool isObnoxious <- false;
	
	bool thirsty <- false;
	bool hungry <- false;
	bool isReporting <- false;
	Guest guestToBeReported <- nil;
	
	list<FoodStore> visitedFoodStores <- [];
	list<DrinksStore> visitedDrinksStores <- [];
	
	int timeInPrison <- 0;
	point targetPoint <- nil;

	reflex dance when: targetPoint = nil {
		speed <- 5 #km/#h;
		thirst <- thirst + rnd(0.0, 3.0);
		hunger <- hunger + rnd(0.0, 1.5);
		bool feelingAdventurous <- flip(0.1);
		
		if (isObnoxious = false) {
			isObnoxious <- flip(0.05);	
		}
		
		list<Guest> guestList <- self neighbors_at (15);
		guestToBeReported <- guestList first_with (each.isBad() = true);

		if (isObnoxious = true) {
			myColor <- #black;
			speed <- 7 #km/#h;
			do wander;
		} else {
			if (thirst >= thirstThreshold) {
				thirsty <- true;
				myColor <- #green;
				// write self.name + ": I am thirsty!";
				
				if (!empty(visitedDrinksStores) and !feelingAdventurous) {
					// write self.name + "i have visited some stores and am not adventurours.";
					int visitedStoreIndex <- rnd(0,length(visitedDrinksStores) - 1);
					// write self.name + "visited drinks store index is: " + visitedStoreIndex;
					targetPoint <- visitedDrinksStores[visitedStoreIndex].location;
				} else {
					// write self.name + "do not know any drinks store or feelina adventurous is true: " + feelingAdventurous; 
					targetPoint <- informationCenterLocation;	
				}
			} else if (hunger >= hungerThreshold) {
				hungry <- true;
				myColor <- #purple;
				// write self.name + ": I am hungry!";
				
				if (!empty(visitedFoodStores) and !feelingAdventurous) {
					int visitedFoodStoreIndex <- rnd(0,length(visitedFoodStores) - 1);
					// write self.name + "visited food store index is: " + visitedFoodStoreIndex;
					targetPoint <- visitedFoodStores[visitedFoodStoreIndex].location;
				} else {
					// write self.name + "do not know any food store or feelina adventurous is true: " + feelingAdventurous;
					targetPoint <- informationCenterLocation;	
				}
			} else if (guestToBeReported != nil) {
				// write self.name + "going to report obnoxious person: " + guestToBeReported.name;
				isReporting <- true;
				targetPoint <- informationCenterLocation;
				
				// go to information center
				// report to the police
			} else {
				do wander;
			}
			
		}
	}
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	reflex enterPlace when: targetPoint != nil and location distance_to(targetPoint) < 1 {
		InformationCenter infoCenter <- InformationCenter closest_to(location);
		DrinksStore drinkStore <- DrinksStore closest_to(location);
		FoodStore foodStore <- FoodStore closest_to(location);
		SecurityGuard guard <- infoCenter.getGuard();
		Prison prison <- Prison closest_to(location);
		
		if (infoCenter != nil and infoCenter.location = targetPoint) {
			// write "Here in info center!";
			if (thirsty = true) {
				list<DrinksStore> drinkStoresList <- infoCenter.getDrinksStores();
				int drinkStoreIndex <- rnd(0,length(drinkStoresList) - 1);
				// write "store index: " + drinkStoreIndex;
				targetPoint <- drinkStoresList[drinkStoreIndex].location;
			} else if (hungry = true) {
				list<FoodStore> foodStoresList <- infoCenter.getFoodStores();
				int foodStoreIndex <- rnd(0, length(foodStoresList) - 1);
				// write "food store index: " + foodStoreIndex;
				targetPoint <- foodStoresList[foodStoreIndex].location;
			} else if (isReporting = true) {
				
				targetPoint <- guard.location;
				do goto target: guard;
				// set location of police guard and inform him!
			}
			
			infoCenter <- nil;
		} else if (drinkStore != nil and drinkStore.location = targetPoint) {
			// write "Here in reflex drink store";
			// add store to memory
			if(!(visitedDrinksStores contains drinkStore)) {
				add drinkStore to: visitedDrinksStores;	
			}
			
			// write "Here in asking the drink store";
			thirst <- 0.0;
			targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
			myColor <- #red;
			thirsty <- false;
			
			drinkStore <- nil;
		} else if (foodStore != nil and foodStore.location = targetPoint) {
			// write "Here in reflex food store";
			// add store to memory
			if(!(visitedFoodStores contains foodStore)) {
				add foodStore to: visitedFoodStores;	
			}
			
			// write "Here in asking the food store";
			hunger <- 0.0;
			targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
			myColor <- #red;
			hungry <- false;
			
			foodStore <- nil;
		} else if (targetPoint != prisonLocation and guard != nil and guard.location = targetPoint) {
			 write self.name + ": Here near security gueard";
			
			ask guard {
				do captureBadGuest(myself.guestToBeReported);
//				do goto target: myself.guestToBeReported;
				myself.speed <- 10.0 #km/#h;
				myself.targetPoint <- myself.guestToBeReported.location;
			}
			
			isReporting <- false;
			guestToBeReported <- nil;
			guard <- nil;
//			targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
		} else if (prison != nil and prison.location = targetPoint) {
			write self.name + " is in prison";
			self.isObnoxious <- false;
			if (timeInPrison > 0) {
				write self.name + " time left in prison " + timeInPrison;
				timeInPrison <- timeInPrison - 1;
			} else {
				write self.name + " going out of prison " + timeInPrison;
				self.myColor <- #red;
				self.speed <- 5 #km/#h;
				targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
			}
		} else {
			targetPoint <- nil;
		} 
	}
	
	bool isBad {
		return isObnoxious;
	}
	
	aspect default {
		draw sphere(1) at: location color: myColor;
	}
}

/**
 * Information Center Species 
 */
species InformationCenter {
	rgb myColor <- #blue;

	init {
		location <- informationCenterLocation;	
	}
	
	list<DrinksStore> getDrinksStores {
		return DrinksStore.population;
	}
	
	list<FoodStore> getFoodStores {
		return FoodStore.population;
	}
	
	
	
	SecurityGuard getGuard {
		SecurityGuard guard <- SecurityGuard closest_to(location);
		return guard;
	}

	aspect default {
		draw cube(5) at: location color: myColor;
	}
}

species Store {
	rgb storeColor <- #green;
	
	aspect default {
		draw pyramid(5) at: location color: storeColor;
	}
}

species FoodStore parent: Store {
	init {
		storeColor <- #purple;
	}
}

species DrinksStore parent: Store {
	init {
		storeColor <- #green;
	}
}

species Prison {
	rgb myColor <- #grey;
	
	init {
		location <- prisonLocation;
	}
	
	aspect default {
		draw square(5) at: location color: myColor;
	}
}

experiment fest_experiment type: gui {
	output {
		display displayFest type: opengl {
			species Guest;
			species InformationCenter;
			species FoodStore;
			species DrinksStore;
			species SecurityGuard;
			species Prison;
		}	
	}
}