# CLAUDE.md - pfQuest Navigation Enhancement

## Mission
Enhance pfQuest addon navigation from distance-based to intelligent quest level prioritization for Classic WoW. Focus on efficient quest progression through level-appropriate routing.

## Navigation System Architecture

### Core Files
- **route.lua**: Main navigation logic, sorting algorithms, arrow display
- **config.lua**: Configuration options and GUI definitions
- **map.lua**: Node management, coordinate handling, pin system
- **database.lua**: Quest data processing, node metadata generation

### Key Navigation Components

**route.lua**:
- Line 175-194: `sortfunc()` - Quest prioritization algorithm
- Line 219-241: Zone filtering logic
- Line 13-33: `GetNearest()` - Distance calculations
- Line 176-295: Main OnUpdate handler for routing

**map.lua**:
- Line 888: `pfQuest.route:AddPoint()` - Adds nodes to routing system
- Line 467: `pfMap:AddNode()` - Creates map nodes
- Line 872-920: Node rendering and route integration

### Quest Node Data Structure
Each route node contains:
- `[1]` = x coordinate
- `[2]` = y coordinate  
- `[3]` = metadata object (qlvl, layer, zone, title, QTYPE)
- `[4]` = calculated distance to player

### Layer System
- Layer 1-2: Quest starters (available quests)
- Layer 3: Quest objectives (active quest goals)
- Layer 4: Quest turn-ins (completed quests)
- Layer 9+: Clustered objectives

### Current Features
- Level-based routing: `routebylevel` config option
- Zone filtering: `routebyzone` config option
- Turn-in priority: Layer 4 always prioritized
- Distance tiebreaker for same-level quests

## Configuration
New options added to Routes section:
- "Route By Quest Level" (routebylevel)
- "Route By Current Zone Only" (routebyzone)

## Maintenance Commands

### rebase
When user types "rebase", execute this workflow to sync with upstream:

```bash
# 1. Fetch latest upstream changes
git fetch upstream

# 2. Check for new commits
git log --oneline upstream/master ^master

# 3. Perform rebase
git rebase upstream/master

# 4. If conflicts occur:
#    - Auto-resolve if changes are in different sections
#    - Prompt user only for overlapping changes in route.lua sortfunc or config options
#    - Continue with: git rebase --continue

# 5. Force push to origin
git push origin master --force
```

**Current Status**: Fork synced with upstream at commit ba09ad8
**Our Enhancement**: 1 commit (0d10ed3) - Level-based quest routing