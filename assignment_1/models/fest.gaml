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
 * Gues Species
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
	
	point targetPoint <- nil;

	reflex dance when: targetPoint = nil {
		thirst <- thirst + rnd(0.0, 3.0);
		hunger <- hunger + rnd(0.0, 1.5);
		
		if (thirst >= thirstThreshold) {
			thirsty <- true;
			myColor <- #green;
			write self.name + ": I am thirsty!";
			targetPoint <- informationCenterLocation;
		} else if (hunger >= hungerThreshold) {
			hungry <- true;
			myColor <- #purple;
			write self.name + ": I am hungry!";
			targetPoint <- informationCenterLocation;
		} else {
			do wander;
		}
	}
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	reflex enterStore when: targetPoint != nil and location distance_to(targetPoint) < 1 {
		InformationCenter infoCenter <- InformationCenter closest_to(location);
		DrinksStore drinkStore <- DrinksStore closest_to(location);
		FoodStore foodStore <- FoodStore closest_to(location);
		
		if (infoCenter != nil and infoCenter.location = targetPoint) {
			write "Here in info center!";
			if (thirsty = true) {
				list<DrinksStore> drinkStoresList <- infoCenter.getDrinksStores();
				int drinkStoreIndex <- rnd(0, length(drinkStoresList) - 1);
				write "drinks store index: " + drinkStoreIndex;
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
			thirst <- 0.0;
			thirsty <- false;
			targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
			myColor <- #red;
				
			drinkStore <- nil;
		} else if (foodStore != nil and foodStore.location = targetPoint) {
			write "Here in reflex food store";
			hunger <- 0.0;
			hungry <- false;
			targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
			myColor <- #red;
			
			foodStore <- nil;
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