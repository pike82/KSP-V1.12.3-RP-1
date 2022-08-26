
//General Credits, script and ideas came from the following:
// http://youtube.com/gisikw

///// Download Dependant libraies

///////////////////////////////////////////////////////////////////////////////////
///// List of functions that can be called externally
///////////////////////////////////////////////////////////////////////////////////

	// local Docking is lex(
		// "dok_dock", ff_dok_dock@,
		// "undock",ff_undock@
	// ).

////////////////////////////////////////////////////////////////
//File Functions
////////////////////////////////////////////////////////////////

//Credits: http://youtube.com/gisikw

//TODO: work out why the exclusion function is not working correctly
//TODO: Test Main engine components of the function.
//TODO: Further tests from multiple orientations to ensure it works from multiple angles.
  
	FUNCTION ff_dok_dock {
	PARAMETER dockingPort, targetPort, targetVessel, Safe_dist is 75, SpeedMod is 1.
	    dockingPort:CONTROLFROM().
		Print "Controlling from Port location".
		RCS ON.
		If (SHIP:VELOCITY:ORBIT - targetVessel:VELOCITY:ORBIT):MAG < 0{ //test if we are moving towards or away from the target (True is away from the target)
			Print "Zeroing Velocity".
			hf_dok_kill_relative_velocity(targetPort, 0.1).  //Kill relative velocity to under 0.1 m/s if we are heading away from the target) using main engine
		}
	    Else {
			hf_dok_kill_relative_velocity(targetPort, 1.5). //Kill relative velocity to 1.5 m/s
		}
		Print "Ensuring Range".
	    hf_dok_ensure_range(targetVessel, dockingPort, Safe_dist, 1). //first check is to ensure not within safe distance, if we are move out at 1 m/s to ensure we have appropriate clearance before commencing the docking

		Print "Sideswipe Speed 1".
		hf_dok_sideswipe(targetPort, dockingPort, Safe_dist, Safe_dist*4, 5*SpeedMod, 0.01). Clearscreen. Print "Sideswipe Speed 2".
		hf_dok_sideswipe(targetPort, dockingPort, Safe_dist, Safe_dist*3, 3.5*SpeedMod, 0.01). Clearscreen. Print "Sideswipe Speed 3".
		hf_dok_sideswipe(targetPort, dockingPort, Safe_dist, Safe_dist*2, 2.5*SpeedMod, 0.01). Clearscreen. Print "Sideswipe Speed 4".
		hf_dok_sideswipe(targetPort, dockingPort, Safe_dist, Safe_dist*1.05, 2*SpeedMod, 0.01). 
	   
		Print "Locking Port Orientation".
		// rotate so the ports are acing each other
		LOCK STEERING TO -1 * targetPort:PORTFACING:VECTOR.
		Print "Commencing Approach using RCS".
		Print "Approach 1".
		hf_dok_approach_port(targetPort, dockingPort, max(Safe_dist,20), 2*SpeedMod). Clearscreen. Print "Approach 2".
		hf_dok_approach_port(targetPort, dockingPort, max(Safe_dist/2,15), 1.5*SpeedMod). Clearscreen. Print "Approach 3".
		hf_dok_approach_port(targetPort, dockingPort, max(Safe_dist/4,12.5), 0.75*SpeedMod). Clearscreen. Print "Approach 4".
		hf_dok_approach_port(targetPort, dockingPort, 10, max(0.3,0.3*SpeedMod)). Clearscreen. Print "Approach 5".
		hf_dok_approach_port(targetPort, dockingPort, 5, max(0.2,0.2*SpeedMod)). Clearscreen. Print "Final Approach".
		hf_dok_approach_port(targetPort, dockingPort, 1.0, max(0.1,0.1*SpeedMod)).  
		hf_dok_approach_port(targetPort, dockingPort, 0.1, max(0.025,0.1*SpeedMod)). 
		RCS OFF.
		Unlock ALL.
	}// End Function
	
///////////////////////////////////////////////////////////////////////////////////	
//Credits: Own
	
	FUNCTION ff_undock {
	PARAMETER undockingPort, targetPort, targetVes, Safe_dist is 150.
	    undockingPort:CONTROLFROM().
		wait 1.0.
		dockingPort:undock.
		RCS ON.
		Print "Ensuring Range".
	    hf_undock_move(targetVes, targetPort, Safe_dist*0.1, 0.25). //first check is to ensure not within safe distance, if we are move out at 0.25 m/s to ensure we have appropriate clearance before speeding up
		hf_undock_move(targetVes, targetPort, Safe_dist*0.2, 1). //first check is to ensure not within safe distance, if we are move out at 1 m/s to ensure we have appropriate clearance before before speeding up
		hf_undock_move(targetVes, targetPort, Safe_dist, 2). //first check is to ensure not within safe distance, if we are move out at 2 m/s to ensure we have appropriate clearance before before speeding up
		RCS OFF.
	}// End Function

///////////////////////////////////////////////////////////////////////////////////
//Helper Functions
/////////////////////////////////////////////////////////////////////////////////////
	
//Credits: Own

	FUNCTION hf_undock_move {
	PARAMETER targetVessel, dockingPort, distance, speed.
		LOCK STEERING TO -1 * targetPort:PORTFACING:VECTOR.
		LOCK relativePosition TO SHIP:POSITION - targetVessel:POSITION.
		If relativePosition:mag < distance{
			UNTIL FALSE {
				hf_dok_translate(((targetPort:PORTFACING:VECTOR):normalized * speed)). 
				IF relativePosition:mag > distance BREAK. // once outside the minimum range break
				WAIT 0.01.
			}
			hf_dok_translate(V(0,0,0)). // halts RCS by saying the target vector change is zero (note the ship may still be moveing towards the target)
		} // End if
	}// End Function
	
///////////////////////////////////////////////////////////////////////////////////	
//Credits: http://youtube.com/gisikw	
	
	FUNCTION hf_dok_ensure_range {
	PARAMETER targetVessel, dockingPort, distance, speed.

	  LOCK relativePosition TO SHIP:POSITION - targetVessel:POSITION.
	  LOCK departVector TO (relativePosition:normalized * (distance + 2)) - relativePosition.
	  LOCK relativeVelocity TO SHIP:VELOCITY:ORBIT - targetVessel:VELOCITY:ORBIT.
		If relativePosition:mag < (distance + 1){
			UNTIL FALSE {
				hf_dok_translate((departVector:normalized * speed) - relativeVelocity). // if inside the minimimu range move outside the minimum range
				IF relativePosition:mag > (distance + 1) BREAK. // once outside the minimum range break
				WAIT 0.01.
				Print "Slow backoff" + relativePosition:mag AT (0,9).
			}
			hf_dok_translate(V(0,0,0)). // halts RCS by saying the target vector change is zero (note the ship may still be moving towards the target)
		} // End if
	}// End Function
	
///////////////////////////////////////////////////////////////////////////////////
//Credits: http://youtube.com/gisikw
	
	FUNCTION hf_dok_translate { // move the ship in the direction of the vector inputed as a parameter
	PARAMETER vector.
	  
		IF vector:MAG > 1 {
			SET vector TO vector:normalized.
		}
		//SET SHIP:CONTROL:TRANSLATION to vector.
		SET SHIP:CONTROL:STARBOARD  TO vector * SHIP:FACING:STARVECTOR.
		SET SHIP:CONTROL:FORE       TO vector * SHIP:FACING:FOREVECTOR.
		SET SHIP:CONTROL:TOP        TO vector * SHIP:FACING:TOPVECTOR.
		//Print (vector * SHIP:FACING:STARVECTOR).
		//Print (vector * SHIP:FACING:FOREVECTOR).
		//Print (vector * SHIP:FACING:TOPVECTOR).
	}// End Function
	
///////////////////////////////////////////////////////////////////////////////////
//Credits: http://youtube.com/gisikw	
	FUNCTION hf_dok_kill_relative_velocity {
	PARAMETER targetPort, speed.

	  LOCK relativeVelocity TO SHIP:VELOCITY:ORBIT - targetPort:SHIP:VELOCITY:ORBIT.
	  UNTIL relativeVelocity:MAG < speed {
		hf_dok_translate(-relativeVelocity).
	  }
	  hf_dok_translate(V(0,0,0)).
	}// End Function
	
///////////////////////////////////////////////////////////////////////////////////
//Credits: Own with ideas from http://youtube.com/gisikw

	FUNCTION hf_dok_sideswipe {
	PARAMETER targetPort, dockPort, Safe_distance, distance, speed, Step_Time.
	 
	  dockPort:CONTROLFROM().
	  Print "Setting up Reference Frame".
	  Wait 0.1.
	  // Set up reference directions
	  LOCK Tar_Face TO targetPort:SHIP:FACING:VECTOR.
	  LOCK Tar_Up TO targetPort:SHIP:FACING:TOPVECTOR.
	  LOCK Tar_Star TO targetPort:SHIP:FACING:STARVECTOR.
	  LOCK dok_Face TO dockPort:SHIP:FACING:VECTOR.  
	  LOCK dok_Up TO dockPort:SHIP:FACING:TOPVECTOR.  
	  LOCK dok_Star TO dockPort:SHIP:FACING:STARVECTOR. 
	  LOCK relativeVelocity TO SHIP:VELOCITY:ORBIT - targetPort:SHIP:VELOCITY:ORBIT. //Bos are in SOI Raw Vector // + SHIP:BODY:POSITION is used to bring SOI Raw vector to Ship RAW vector

	  
	  Print "Setting up reference nodes".
	  Wait 0.1.
	  
	  //Set reference nodes (vectors from the target port)
	  Set Fwd_node to Tar_Face*Safe_distance*1.5.
	  Set Back_node to Tar_Face*-Safe_distance*1.45.
	  Set Stbd_node to Tar_Star*Safe_distance*1.45.
	  Set Port_node to Tar_Star*-Safe_distance*1.45.
	  Set Up_node to Tar_Up*Safe_distance*1.45.
	  Set Down_node to Tar_Up*-Safe_distance*1.45.
	  
		//Create vectors to reference nodes
	  Lock Centre_node_vec to targetPort:NODEPOSITION - dockPort:NODEPOSITION.
	  Lock Fwd_node_vec to Fwd_node + Centre_node_vec.
	  Lock Back_node_vec to Back_node + Centre_node_vec.
	  Lock Stbd_node_vec to Stbd_node + Centre_node_vec.
	  Lock Port_node_vec to Port_node + Centre_node_vec.
	  Lock Up_node_vec to Up_node + Centre_node_vec.
	  Lock Down_node_vec to Down_node + Centre_node_vec.
	  
	  LOCK STEERING TO LOOKDIRUP(-targetPort:PORTFACING:VECTOR, targetPort:PORTFACING:UPVECTOR).
	  LOCK approachVector to Fwd_node_vec.
	  Set approachVector_ang to 90.
	  Set text_node to "Start".
	  
	  Until False{
		Clearscreen.
		CLEARVECDRAWS().
		Set text_node to "Start".
		Print "Inside Loop".
		  
		//Set up Exclusion zone angles
		local min_Ang is arcsin(Safe_distance/Centre_node_vec:mag).
		local rel_Ang is Vang(Centre_node_vec:normalized, relativeVelocity:normalized).
		
		
		//Identify the reference node the ship is pointing towards he closest without entering the exclusion zone
		If (hf_dok_Exclusion_test (Safe_distance, Centre_node_vec, approachVector) = False) OR (approachVector_ang > 10) { //if we are not heading towards a node or about to go into the exclusion zone find a new approach vector.
			
			If hf_dok_Exclusion_test (Safe_distance, Centre_node_vec, Fwd_node_vec) { // if there is a claer path to the fwd node head here
				Lock approachVector to Fwd_node_vec.
				Set approachVector_ang to hf_dok_Exclusion_Ang (Safe_distance, Centre_node_vec, Fwd_node_vec).
				Print "Fwd Node".
				Set text_node to "Fwd".
			}
			Else { // otherwise head to a side node
				If hf_dok_Exclusion_test (Safe_distance, Centre_node_vec, Stbd_node_vec) AND hf_dok_Exclusion_Ang (Safe_distance, Centre_node_vec, Stbd_node_vec) < approachVector_ang {
					Lock approachVector to Stbd_node_vec. 
					Set approachVector_ang to hf_dok_Exclusion_Ang (Safe_distance, Centre_node_vec, Stbd_node_vec).
					Print "Stbd Node".
					Set text_node to "Stbd".
				}.
				If hf_dok_Exclusion_test (Safe_distance, Centre_node_vec, Port_node_vec) AND hf_dok_Exclusion_Ang (Safe_distance, Centre_node_vec, Port_node_vec) < approachVector_ang {
					Lock approachVector to Port_node_vec.
					Set approachVector_ang to hf_dok_Exclusion_Ang (Safe_distance, Centre_node_vec, Port_node_vec).
					Print "Port Node".
					Set text_node to "Port".
				}.
				If hf_dok_Exclusion_test (Safe_distance, Centre_node_vec, Up_node_vec) AND hf_dok_Exclusion_Ang (Safe_distance, Centre_node_vec, Up_node_vec) < approachVector_ang {
					Lock approachVector to Up_node_vec.
					Set approachVector_ang to hf_dok_Exclusion_Ang (Safe_distance, Centre_node_vec, Up_node_vec).
					Print "Up Node".
					Set text_node to "Up".
				}.
				If hf_dok_Exclusion_test (Safe_distance, Centre_node_vec, Down_node_vec) AND hf_dok_Exclusion_Ang (Safe_distance, Centre_node_vec, Down_node_vec) < approachVector_ang {
					Lock approachVector to Down_node_vec.
					Set approachVector_ang to hf_dok_Exclusion_Ang (Safe_distance, Centre_node_vec, Down_node_vec).
					Print "Down Node".
					Set text_node to "Down".
				}.
			} // end else
		} //end main IF	
		
		//Set approachVector to relativeVelocity + approachVector.
		//IF (abs(Centre_node_vec:MAG) < (distance + 2) ) {
		IF ((approachVector:MAG < 10) or (Centre_node_vec:mag < Distance)) AND (Centre_node_vec:mag > Safe_distance*1.45){
			BREAK. // if at the distance away from the craft break the loop
		}
		//LOCK STEERING TO approachVector.
		Print "Translating Speed:" + Speed.
		Print "Fwd Node Clear:" + hf_dok_Exclusion_test (Safe_distance, Centre_node_vec, Fwd_node_vec).
		Print "Target node:" +text_node.
		Print "Approach Angle:" + approachVector_ang.
		Print "Distance from Target Node:" + approachVector:MAG.
		Print "Distance from Target vessel:" + Centre_node_vec:mag.
		Print "Loop End Distance:" + Distance.
		Print "Target Node Transit Safe Distance Allowance:" + Safe_distance*1.45.
		Print (Vang(approachVector,relativeVelocity)).
		//If (Vang(approachVector,relativeVelocity) > 5) {
			//RCS ON.
			hf_dok_translate((approachVector:normalized * speed)- relativeVelocity).
			//RCS OFF.
		//}

	 VECDRAW(
		V(0,0,0),
		Fwd_node_vec:normalized*3,
		RGB(1,0,0),
		"Fore Vector",
		1.2,
		TRUE
	  ).
	  
		VECDRAW(
		V(0,0,0),
		approachVector:normalized*3,
		RGB(0,0,1),
		"Closest_node_vec_pos",
		1.2,
		TRUE
	  ).
	   
		VECDRAW(
		V(0,0,0),
		Centre_node_vec:normalized*3,
		RGB(1,1,0),
		"Centre",
		1.2,
		TRUE
	  ).
		VECDRAW(
		V(0,0,0),
		relativeVelocity:normalized*3,
		RGB(1,1,1),
		"Relative velocity",
		1.2,
		TRUE
	  ).
		  
		Wait Step_Time.  // Recalculate every step time
	  } // End of Until
	  
		hf_dok_translate(V(0,0,0)).
		
	} // End of dok_sideswipe function
	
///////////////////////////////////////////////////////////////////////////////////
//Credits: Own
	
	FUNCTION hf_dok_Exclusion_test {
	PARAMETER distance, Centre_node_vec, test_Vector.

		Set min_Ang to arcsin(distance/Centre_node_vec:mag).
		Set rel_Ang to Vang (Centre_node_vec:normalized, test_Vector:normalized).
		
		If min_Ang < rel_Ang {
			//We are missiong the exclusion zone.
			Return True.
		}
		Else {
			//We will enter the exclusion zone.
			Return False.
		}
	}// End Function
	
///////////////////////////////////////////////////////////////////////////////////
//Credits: Own
	
	FUNCTION hf_dok_Exclusion_Ang {
	PARAMETER distance, Centre_node_vec, test_Vector.

		Set min_Ang to arcsin(distance/Centre_node_vec:mag).
		Set rel_Ang to Vang (Centre_node_vec:normalized, test_Vector:normalized).
		Return abs(rel_Ang).
	}// End Function
	
///////////////////////////////////////////////////////////////////////////////////
//Credits: http://youtube.com/gisikw	
	FUNCTION hf_dok_approach_port {
	PARAMETER targetPort, dockPort, distance, speed.

		dockPort:CONTROLFROM().

		LOCK distanceOffset TO targetPort:PORTFACING:VECTOR * distance.
		LOCK approachVector TO targetPort:NODEPOSITION - dockPort:NODEPOSITION + distanceOffset.
		LOCK relativeVelocity TO SHIP:VELOCITY:ORBIT - targetPort:SHIP:VELOCITY:ORBIT.
		LOCK STEERING TO LOOKDIRUP(-targetPort:PORTFACING:VECTOR, targetPort:PORTFACING:UPVECTOR).

		Set PM to targetPort:GetMODULE("ModuleDockingNode").

		UNTIL PM:HASEVENT("undock"){//dockingPort:STATE <> "Ready" {
			hf_dok_translate((approachVector:normalized * speed) - relativeVelocity).
			LOCAL distanceVector IS (targetPort:NODEPOSITION - dockPort:NODEPOSITION).
			Print "Node Distance: " + distance AT (0,10).
			Print "Distance: " + distanceVector:MAG AT (0,11).
			Print "Node Speed: " + speed AT (0,12).
			Print "Speed: " + relativeVelocity:mag AT (0,13).

			IF VANG(dockPort:PORTFACING:VECTOR, distanceVector) < 2 AND abs(distance - distanceVector:MAG) < 0.3 {
				BREAK.
			}
			WAIT 0.01.
		}

		hf_dok_translate(V(0,0,0)).
	}// End Function
	
