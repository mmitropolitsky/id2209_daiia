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
	
	float hungerThreshold <- 20.0;
	float thirstThreshold <- 20.0;

	
	init {
		create Guest number: numberOfGuests;
		create InformationCenter number: 1;
		create FoodStore number: 2;
		create DrinksStore number: 2;
		create SecurityGuard number: 1;
	}
}

species SecurityGuard skills: [moving] {
	init {
		speed <- 10.0 #km/#h;
	}
	
	rgb guardColor <- #black;
	point targetPoint <- nil;
	Guest target <- nil;
	
	reflex wait when: targetPoint = nil {
		InformationCenter infoCenter <- InformationCenter closest_to(location);
		list<Guest> guestList <- Guest at_distance(15);
		Guest badGuest <- guestList first_with (each.isBad() = true);
		if (badGuest != nil) {
			do captureBadGuest(badGuest);
		}
	}
	
	reflex capture when: target != nil {
		do goto target: target;
		
		if (target != nil and target.isBad()) {
			ask target {
				write "killing target" + self.name;
				do die;
			}
		}
	}

	action captureBadGuest(Guest badGuest) {
		write self.name + ": here at capture bad guest action of guard for guest: " + badGuest.name;
		
		target <- badGuest;
//		do goto target: badGuest;
		
//		write self.name + ": here at capture after goto for guest: " + badGuest.name;
//		if (badGuest != nil and badGuest.isBad) {
//			ask badGuest {
//				do die;
//			}
//		}
	}
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
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
	
	
	
	
	point targetPoint <- nil;

	reflex dance when: targetPoint = nil {
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
				write self.name + ": I am thirsty!";
				
				if (!empty(visitedDrinksStores) and !feelingAdventurous) {
					write self.name + "i have visited some stores and am not adventurours.";
					int visitedStoreIndex <- rnd(0,length(visitedDrinksStores) - 1);
					write self.name + "visited drinks store index is: " + visitedStoreIndex;
					targetPoint <- visitedDrinksStores[visitedStoreIndex].location;
				} else {
					write self.name + "do not know any drinks store or feelina adventurous is true: " + feelingAdventurous; 
					targetPoint <- informationCenterLocation;	
				}
			} else if (hunger >= hungerThreshold) {
				hungry <- true;
				myColor <- #purple;
				write self.name + ": I am hungry!";
				
				if (!empty(visitedFoodStores) and !feelingAdventurous) {
					int visitedFoodStoreIndex <- rnd(0,length(visitedFoodStores) - 1);
					write self.name + "visited food store index is: " + visitedFoodStoreIndex;
					targetPoint <- visitedFoodStores[visitedFoodStoreIndex].location;
				} else {
					write self.name + "do not know any food store or feelina adventurous is true: " + feelingAdventurous;
					targetPoint <- informationCenterLocation;	
				}
			} else if (guestToBeReported != nil) {
				write self.name + "going to report obnoxious person: " + guestToBeReported.name;
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
	
	reflex enterStore when: targetPoint != nil and location distance_to(targetPoint) < 1 {
		InformationCenter infoCenter <- InformationCenter closest_to(location);
		DrinksStore drinkStore <- DrinksStore closest_to(location);
		FoodStore foodStore <- FoodStore closest_to(location);
		SecurityGuard guard <- infoCenter.getGuard();
		
		if (infoCenter != nil and infoCenter.location = targetPoint) {
			write "Here in info center!";
			if (thirsty = true) {
				list<DrinksStore> drinkStoresList <- infoCenter.getDrinksStores();
				int drinkStoreIndex <- rnd(0,length(drinkStoresList) - 1);
				write "store index: " + drinkStoreIndex;
				targetPoint <- drinkStoresList[drinkStoreIndex].location;
			} else if (hungry = true) {
				list<FoodStore> foodStoresList <- infoCenter.getFoodStores();
				int foodStoreIndex <- rnd(0, length(foodStoresList) - 1);
				write "food store index: " + foodStoreIndex;
				targetPoint <- foodStoresList[foodStoreIndex].location;
			} else if (isReporting = true) {
				
				targetPoint <- guard.location;
				do goto target: guard;
				// set location of police guard and inform him!
			}
			
			infoCenter <- nil;
		} else if (drinkStore != nil and drinkStore.location = targetPoint) {
			write "Here in reflex drink store";
			// add store to memory
			if(!(visitedDrinksStores contains drinkStore)) {
				add drinkStore to: visitedDrinksStores;	
			}
			
			write "Here in asking the drink store";
			thirst <- 0.0;
			targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
			myColor <- #red;
			thirsty <- false;
			
			drinkStore <- nil;
		} else if (foodStore != nil and foodStore.location = targetPoint) {
			write "Here in reflex food store";
			// add store to memory
			if(!(visitedFoodStores contains foodStore)) {
				add foodStore to: visitedFoodStores;	
			}
			
			write "Here in asking the food store";
			hunger <- 0.0;
			targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
			myColor <- #red;
			hungry <- false;
			
			foodStore <- nil;
		} else if (guard != nil and guard.location = targetPoint) {
			write self.name + ": Here near security gueard";
			
			ask guard {
				do captureBadGuest(myself.guestToBeReported);
			}
			
			isReporting <- false;
			guestToBeReported <- nil;
			guard <- nil;
			targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
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

experiment fest_experiment type: gui {
	output {
		display displayFest type: opengl {
			species Guest;
			species InformationCenter;
			species FoodStore;
			species DrinksStore;
			species SecurityGuard;
		}	
	}
}