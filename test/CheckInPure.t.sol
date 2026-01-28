// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {CheckInPure} from "../src/CheckInPure.sol";

interface Vm {
    function prank(address) external;
    function warp(uint256) external;
}

contract CheckInPureTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    CheckInPure checkIn;
    
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address charlie = address(0xC4A211E);

    function setUp() public {
        // Start at day 1 to avoid issues with day 0
        vm.warp(1 days);
        checkIn = new CheckInPure();
    }

    // Test: Basic check-in functionality
    function testBasicCheckIn() public {
        // Alice checks in
        vm.prank(alice);
        checkIn.checkIn();
        
        // Verify check-in records
        require(checkIn.hasCheckedInToday(alice), "alice should have checked in");
        require(checkIn.getTotalCheckIns(alice) == 1, "alice should have 1 total check-in");
        require(checkIn.getConsecutiveDays(alice) == 1, "alice should have 1 consecutive day");
    }

    // Test: Cannot check-in twice on same day
    function testCannotCheckInTwice() public {
        vm.prank(alice);
        checkIn.checkIn();
        
        // Try to check-in again
        vm.prank(alice);
        try checkIn.checkIn() {
            revert("should not allow double check-in");
        } catch {}
    }

    // Test: Can check-in next day
    function testCheckInNextDay() public {
        // Day 1: Alice checks in (already at 1 day from setUp)
        vm.prank(alice);
        checkIn.checkIn();
        
        require(checkIn.getTotalCheckIns(alice) == 1, "should have 1 check-in");
        require(checkIn.getConsecutiveDays(alice) == 1, "should have 1 consecutive day");
        
        // Day 2: Alice checks in again
        vm.warp(2 days);
        vm.prank(alice);
        checkIn.checkIn();
        
        require(checkIn.getTotalCheckIns(alice) == 2, "should have 2 check-ins");
        require(checkIn.getConsecutiveDays(alice) == 2, "should have 2 consecutive days");
    }

    // Test: Consecutive days tracking
    function testConsecutiveDays() public {
        // Check-in for 5 consecutive days
        for (uint256 i = 1; i <= 5; i++) {
            vm.warp(i * 1 days);
            vm.prank(alice);
            checkIn.checkIn();
            
            require(checkIn.getTotalCheckIns(alice) == i, "total should increase");
            require(checkIn.getConsecutiveDays(alice) == i, "consecutive should increase");
        }
    }

    // Test: Consecutive days break when skip a day
    function testConsecutiveDaysBreak() public {
        // Day 1: Check-in
        vm.warp(1 days);
        vm.prank(alice);
        checkIn.checkIn();
        
        // Day 2: Check-in
        vm.warp(2 days);
        vm.prank(alice);
        checkIn.checkIn();
        
        require(checkIn.getConsecutiveDays(alice) == 2, "should have 2 consecutive days");
        
        // Skip Day 3, check-in on Day 4
        vm.warp(4 days);
        vm.prank(alice);
        checkIn.checkIn();
        
        require(checkIn.getTotalCheckIns(alice) == 3, "should have 3 total check-ins");
        require(checkIn.getConsecutiveDays(alice) == 1, "consecutive should reset to 1");
    }

    // Test: Multiple users check-in independently
    function testMultipleUsers() public {
        // Alice checks in
        vm.prank(alice);
        checkIn.checkIn();
        
        // Bob checks in
        vm.prank(bob);
        checkIn.checkIn();
        
        // Charlie checks in
        vm.prank(charlie);
        checkIn.checkIn();
        
        // Verify all checked in
        require(checkIn.hasCheckedInToday(alice), "alice should have checked in");
        require(checkIn.hasCheckedInToday(bob), "bob should have checked in");
        require(checkIn.hasCheckedInToday(charlie), "charlie should have checked in");
    }

    // Test: Get check-in stats
    function testGetCheckInStats() public {
        // Alice checks in for 3 consecutive days
        for (uint256 i = 1; i <= 3; i++) {
            vm.warp(i * 1 days);
            vm.prank(alice);
            checkIn.checkIn();
        }
        
        (uint256 lastDay, uint256 total, uint256 consecutive, bool checkedInToday) 
            = checkIn.getCheckInStats(alice);
        
        require(lastDay > 0, "last day should be > 0");
        require(total == 3, "total should be 3");
        require(consecutive == 3, "consecutive should be 3");
        require(checkedInToday, "should have checked in today");
    }

    // Test: Batch query hasCheckedInToday
    function testBatchHasCheckedInToday() public {
        // Alice and Bob check-in, Charlie doesn't
        vm.prank(alice);
        checkIn.checkIn();
        
        vm.prank(bob);
        checkIn.checkIn();
        
        // Batch query
        address[] memory users = new address[](3);
        users[0] = alice;
        users[1] = bob;
        users[2] = charlie;
        
        bool[] memory results = checkIn.batchHasCheckedInToday(users);
        
        require(results[0] == true, "alice should have checked in");
        require(results[1] == true, "bob should have checked in");
        require(results[2] == false, "charlie should not have checked in");
    }

    // Test: Batch get check-in stats
    function testBatchGetCheckInStats() public {
        // Alice checks in 3 times
        for (uint256 i = 1; i <= 3; i++) {
            vm.warp(i * 1 days);
            vm.prank(alice);
            checkIn.checkIn();
        }
        
        // Bob checks in 5 times
        for (uint256 i = 1; i <= 5; i++) {
            vm.warp(i * 1 days);
            vm.prank(bob);
            checkIn.checkIn();
        }
        
        // Batch query
        address[] memory users = new address[](3);
        users[0] = alice;
        users[1] = bob;
        users[2] = charlie;
        
        (uint256[] memory lastDays, uint256[] memory totals, uint256[] memory consecutives)
            = checkIn.batchGetCheckInStats(users);
        
        require(lastDays[0] > 0, "alice last day should be > 0");
        require(totals[0] == 3, "alice total should be 3");
        require(consecutives[0] == 3, "alice consecutive should be 3");
        
        require(lastDays[1] > 0, "bob last day should be > 0");
        require(totals[1] == 5, "bob total should be 5");
        require(consecutives[1] == 5, "bob consecutive should be 5");
        
        require(lastDays[2] == 0, "charlie last day should be 0");
        require(totals[2] == 0, "charlie total should be 0");
        require(consecutives[2] == 0, "charlie consecutive should be 0");
    }

    // Test: Query functions for new user
    function testNewUserQueries() public {
        require(checkIn.getLastCheckInDay(alice) == 0, "new user last day should be 0");
        require(checkIn.getTotalCheckIns(alice) == 0, "new user total should be 0");
        require(checkIn.getConsecutiveDays(alice) == 0, "new user consecutive should be 0");
        require(!checkIn.hasCheckedInToday(alice), "new user should not have checked in");
    }

    // Test: Long consecutive streak
    function testLongConsecutiveStreak() public {
        // Check-in for 30 consecutive days
        for (uint256 i = 1; i <= 30; i++) {
            vm.warp(i * 1 days);
            vm.prank(alice);
            checkIn.checkIn();
        }
        
        require(checkIn.getTotalCheckIns(alice) == 30, "should have 30 check-ins");
        require(checkIn.getConsecutiveDays(alice) == 30, "should have 30 consecutive days");
    }

    // Test: Multiple streak breaks and restarts
    function testMultipleStreakBreaks() public {
        // First streak: 3 days
        for (uint256 i = 1; i <= 3; i++) {
            vm.warp(i * 1 days);
            vm.prank(alice);
            checkIn.checkIn();
        }
        require(checkIn.getConsecutiveDays(alice) == 3, "first streak should be 3");
        
        // Break streak (skip day 4), check-in day 5
        vm.warp(5 days);
        vm.prank(alice);
        checkIn.checkIn();
        require(checkIn.getConsecutiveDays(alice) == 1, "should reset to 1");
        require(checkIn.getTotalCheckIns(alice) == 4, "total should be 4");
        
        // Second streak: 2 days
        vm.warp(6 days);
        vm.prank(alice);
        checkIn.checkIn();
        require(checkIn.getConsecutiveDays(alice) == 2, "second streak should be 2");
    }

    // Test: getCurrentDay function
    function testGetCurrentDay() public {
        vm.warp(100 days);
        uint256 currentDay = checkIn.getCurrentDay();
        require(currentDay == 100, "current day should be 100");
    }

    // Test: Version
    function testVersion() public {
        string memory ver = checkIn.version();
        require(keccak256(bytes(ver)) == keccak256(bytes("1.0.0")), "version should be 1.0.0");
    }

    // Test: No external dependencies
    function testNoExternalDependencies() public {
        // Contract should work without any external contracts
        // Just check-in works
        vm.prank(alice);
        checkIn.checkIn();
        
        require(checkIn.hasCheckedInToday(alice), "check-in should work independently");
    }
}

