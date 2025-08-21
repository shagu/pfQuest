# pfQuest Level-Based Routing Bug Report

## Issue Summary
Quest 1141 "The Family and the Fishing Pole" (level 14) is not routing as the next quest despite being the lowest level quest available. The system is routing to higher level quests (15-20) instead, violating the core principle of level-based routing.

## Environment
- **Player Level**: 19
- **Quest Level**: 14 (5 levels below player)
- **pfQuest Config**: `routebylevel = "1"` (level-based routing enabled)
- **Quest Status**: Active in quest log, not completed

## Problem Analysis
After extensive debugging, we confirmed:

1. **Quest 1141 EXISTS** in the quest log system
2. **Quest data is VALID** in the database  
3. **Level-based routing is ENABLED** in config
4. **Quest is NOT COMPLETED** in history
5. **System sees the quest** but routes to higher level alternatives

## Root Cause: Unknown
Despite 6+ hours of systematic investigation, the exact point where quest 1141 gets filtered out of routing remains unidentified.

## Attempted Solutions & Failures

### 1. Priority System Investigation
**Theory**: Quest turn-ins (layer 4) were prioritizing over quest level
**Action**: Modified `route.lua` sortfunc to make quest level PRIMARY priority
**Result**: FAILED - Still routes to higher level quests

### 2. Database Pipeline Debugging
**Theory**: Quest 1141 not making it through SearchQuestID pipeline
**Action**: Added comprehensive debug logging through entire quest processing pipeline
**Result**: INCONCLUSIVE - Quest appears in system but doesn't route

### 3. Fallback System Implementation  
**Theory**: Missing routing data causes quest to be excluded
**Action**: Built fallback system to create routing nodes for quests without coordinates
**Result**: FAILED - Over-engineered, caused initialization errors

### 4. Routing Filter Analysis
**Theory**: Quest 1141 filtered out during pin-to-route conversion
**Action**: Added debug to track quest through routing inclusion criteria
**Result**: INCOMPLETE - Debug added but not tested due to time constraints

### 5. Layer System Investigation
**Theory**: Quest 1141 assigned wrong layer preventing routing inclusion
**Action**: Added objective_c texture mapping to layer 3
**Result**: FAILED - No improvement in routing behavior

### 6. Initialization Error Fixes
**Theory**: pfDatabase null reference preventing proper operation
**Action**: Added null checks in quest.lua:125
**Result**: PARTIAL - Fixed errors but didn't solve routing issue

## Technical Findings

### Confirmed Working Components
- Quest log detection and processing
- Level-based sorting algorithm logic
- Quest metadata extraction (questid, qlvl, etc.)
- Database lookups and quest data retrieval

### Suspected Problem Areas
- **Pin Creation**: Quest may not be creating map pins properly
- **Layer Assignment**: Wrong layer preventing routing inclusion
- **Route Filtering**: Criteria in map.lua:883-890 may exclude quest 1141
- **Coordinate Issues**: Missing or invalid coordinates preventing routing

### Key Code Locations
- `route.lua:177-196`: Level-based sorting function
- `map.lua:883-890`: Routing inclusion criteria
- `database.lua:1104`: SearchQuestID main processing
- `quest.lua:125`: Database initialization check

## Possible Theories (Untested)

### Theory A: Player Level Filtering
Quest 1141 may be excluded due to level difference (player 19, quest 14 = 5 level gap). However, this contradicts the design goal of level-based routing showing lowest available quests.

### Theory B: Routing Criteria Too Restrictive
The routing inclusion logic in `map.lua` may be too restrictive:
```lua
-- Only includes:
-- - Layer 4 turn-ins (if enabled)
-- - Layer 1/2 quest starters (if enabled)  
-- - Layer 3 quest objectives
-- - Special arrow quests
```
Quest 1141 may not meet these criteria.

### Theory C: Missing Quest Objectives Layer
Quest 1141 may not be assigned to layer 3 (quest objectives), preventing it from being included in routing despite being in the quest log.

## Impact
- Level-based routing feature is fundamentally broken
- Players cannot efficiently progress through lowest-level quests first
- Higher level quests taking priority defeats the entire purpose of the feature

## Recommended Next Steps
1. **Simplify debugging**: Focus on ONE specific checkpoint rather than comprehensive pipeline logging
2. **Test Theory B**: Check if quest 1141 creates layer 3 pins
3. **Manual override test**: Force quest 1141 inclusion to verify routing works if quest reaches the system
4. **Consider alternative approach**: May need fundamental redesign of routing inclusion logic

## Conclusion
After extensive investigation, this issue appears to be beyond the scope of rapid debugging. The problem lies somewhere in the complex interaction between quest detection, pin creation, layer assignment, and routing inclusion criteria. A systematic rewrite of the routing logic may be necessary rather than continued debugging of the existing system.

**Status**: UNRESOLVED - Requires fundamental architecture review