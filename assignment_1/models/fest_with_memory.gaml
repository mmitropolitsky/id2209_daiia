/***
* Name: fest
* Author: Milko and Viktoriya
* Description: 
* Tags: Tag1, Tag2, TagN
***/

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
	bool thirsty <- false;
	bool hungry <- false;
	list<FoodStore> visitedFoodStores <- [];
	list<DrinksStore> visitedDrinksStores <- [];
	float distanceFromCurrentLocationToDrinkStore <- 0.0;
	float distanceToFromCurrenctLocationToInfoCenterAndDrinkStore <- 0.0;
	float distanceFromCurrentLocationToFoodStore <- 0.0;
	float distanceToFromCurrenctLocationToInfoCenterAndFoodStore <- 0.0;
	
	point targetPoint <- nil;

	reflex dance when: targetPoint = nil {
		thirst <- thirst + rnd(0.0, 3.0);
		hunger <- hunger + rnd(0.0, 1.5);
		bool feelingAdventurous <- flip(0.7);
		if (thirst >= thirstThreshold) {
			thirsty <- true;
			myColor <- #green;
			write self.name + ": I am thirsty!";
			
			if (!empty(visitedDrinksStores) and !feelingAdventurous) {
				write self.name + "i have visited some stores and am not adventurours.";
				int visitedDrinkStoreIndex <- rnd(0, length(visitedDrinksStores) - 1);
				write self.name + "visited drinks store index is: " + visitedDrinkStoreIndex;
				targetPoint <- visitedDrinksStores[visitedDrinkStoreIndex].location;
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
		} else {
			do wander;
		}
	}
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	//only on the way to the info center
	reflex lookForOtherGuests when: targetPoint = informationCenterLocation {
		// get neighbours on the way to the information centre
		list<Guest> neighbours <- self neighbors_at (5);
		if (!empty(neighbours)) {
			Guest g <- first(neighbours);
			write self.name + " here with guest " + g.name;
			ask g {
				write myself.name + "here at asking guest" + self.name;
					if (myself.thirsty = true) {
						write "I am thirsty and asked a neighbor";
						list<DrinksStore> drinkStores <- self.visitedDrinksStores;
						write "Neighbor knows these stores " + drinkStores;
						if (!empty(drinkStores)) {
							int visitedDrinkStoreIndex <- rnd(0, length(drinkStores) - 1);
							myself.targetPoint <- drinkStores[visitedDrinkStoreIndex].location;
							myself.distanceFromCurrentLocationToDrinkStore
								<- myself.location distance_to (drinkStores[visitedDrinkStoreIndex].location);
							myself.distanceToFromCurrenctLocationToInfoCenterAndDrinkStore
								<- myself.location distance_to (informationCenterLocation) +
									informationCenterLocation distance_to (drinkStores[visitedDrinkStoreIndex].location);
							write "Guest " + self.name + " told " + myself.name + " to visit drink store " + drinkStores[visitedDrinkStoreIndex].name;
						} else {
							write "Guest " + self.name + " did not know any stores. " + myself.name + " back to info.";
							myself.targetPoint <- informationCenterLocation;
						}
					} else if (myself.hungry = true) {
						list<FoodStore> foodStores <- self.visitedFoodStores;
						if (!empty(foodStores)) {
							int visitedFoodStoreIndex <- rnd(0, length(foodStores) - 1);
							myself.targetPoint <- foodStores[visitedFoodStoreIndex].location;
							myself.distanceFromCurrentLocationToFoodStore
								<- myself.location distance_to (foodStores[visitedFoodStoreIndex].location);
							myself.distanceToFromCurrenctLocationToInfoCenterAndFoodStore
								<- myself.location distance_to (informationCenterLocation) +
									informationCenterLocation distance_to (foodStores[visitedFoodStoreIndex].location);
							write "Guest " + self.name + " told " + myself.name + " told me to visit food store " + foodStores[visitedFoodStoreIndex].name;
						} else {
							myself.targetPoint <- informationCenterLocation;
							write "Guest " + self.name + " did not know any stores. " + myself.name + " back to info.";
						}
					}
			}
		}
	}

	reflex enterStore when: targetPoint != nil and location distance_to(targetPoint) < 1 {
		InformationCenter infoCenter <- InformationCenter closest_to(location) as InformationCenter;
		DrinksStore drinkStore <- DrinksStore closest_to(location) as DrinksStore;
		FoodStore foodStore <- FoodStore closest_to(location) as FoodStore;
		
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
			}

			infoCenter <- nil;
		} else if (drinkStore != nil and drinkStore.location = targetPoint) {
			write "Here in reflex drink store";
			// add store to memory
			if(!(visitedDrinksStores contains drinkStore)) {
				add drinkStore to: visitedDrinksStores;	
			}
			
			thirst <- 0.0;
			targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
			myColor <- #red;
			thirsty <- false;

			drinkStore <- nil;
			if (distanceFromCurrentLocationToDrinkStore != distanceToFromCurrenctLocationToInfoCenterAndDrinkStore) {
				write "Distances by asking other guest: " + distanceFromCurrentLocationToDrinkStore;
				write "Distances by going to info center: " + distanceToFromCurrenctLocationToInfoCenterAndDrinkStore;
				distanceFromCurrentLocationToDrinkStore <- 0.0;
				distanceToFromCurrenctLocationToInfoCenterAndDrinkStore <- 0.0;
			}


		} else if (foodStore != nil and foodStore.location = targetPoint) {
			write "Here in reflex food store";
			// add store to memory
			if(!(visitedFoodStores contains foodStore)) {
				add foodStore to: visitedFoodStores;	
			}
			
			hunger <- 0.0;
			targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
			myColor <- #red;
			hungry <- false;

			foodStore <- nil;

			if (distanceFromCurrentLocationToFoodStore != distanceToFromCurrenctLocationToInfoCenterAndFoodStore) {
				write "Distances by asking other guest: " + distanceFromCurrentLocationToFoodStore;
				write "Distances by going to info center: " + distanceToFromCurrenctLocationToInfoCenterAndFoodStore;
				distanceFromCurrentLocationToFoodStore <- 0.0;
				distanceToFromCurrenctLocationToInfoCenterAndFoodStore <- 0.0;
			}

		} else {
			targetPoint <- nil;
		} 
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
		}	
	}
}