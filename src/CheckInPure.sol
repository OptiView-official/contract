// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {TimeUtils} from "./lib/TimeUtils.sol";

/**
 * @title CheckInPure - Pure Decentralized Check-in Contract
 * @notice Records daily check-ins without any points or external dependencies
 * @dev Fully decentralized, no admin privileges, no external calls
 *      Once per day check-in, resets at UTC 0:00
 *      No points, no rewards, just pure check-in records
 */
contract CheckInPure {
    /// @notice Records user's last check-in UTC day
    /// @dev User address => UTC day (block.timestamp / 1 days)
    mapping(address => uint256) public lastCheckInDay;
    
    /// @notice Records user's total check-in count (lifetime)
    mapping(address => uint256) public totalCheckIns;
    
    /// @notice Records user's consecutive check-in days
    mapping(address => uint256) public consecutiveDays;
    
    /// @notice Check-in successful event
    event CheckedIn(
        address indexed user, 
        uint256 day, 
        uint256 totalCount, 
        uint256 consecutive
    );

    /**
     * @notice User check-in
     * @dev Anyone can call this function to record their daily check-in
     * 
     * Rules:
     * - Can check-in once per day
     * - Days calculated by UTC time (resets at UTC 0:00)
     * - No points, no rewards, just records
     * - Tracks total and consecutive check-ins
     * 
     * Restrictions:
     * - Can only check-in once per day
     * - Must be a new day (current day > last check-in day)
     */
    function checkIn() external {
        uint256 currentDay = TimeUtils.currentUtcDay();
        uint256 lastDay = lastCheckInDay[msg.sender];
        
        require(currentDay > lastDay, "already checked in today");
        
        // Update check-in day
        lastCheckInDay[msg.sender] = currentDay;
        
        // Increment total check-ins
        totalCheckIns[msg.sender] += 1;
        
        // Update consecutive days
        if (lastDay > 0 && currentDay == lastDay + 1) {
            // Consecutive check-in (yesterday -> today)
            consecutiveDays[msg.sender] += 1;
        } else if (lastDay > 0) {
            // Broke the streak, restart
            consecutiveDays[msg.sender] = 1;
        } else {
            // First check-in ever
            consecutiveDays[msg.sender] = 1;
        }
        
        emit CheckedIn(
            msg.sender, 
            currentDay, 
            totalCheckIns[msg.sender],
            consecutiveDays[msg.sender]
        );
    }

    /**
     * @notice Query user's last check-in day
     * @param user User address
     * @return UTC day (0 means never checked in)
     */
    function getLastCheckInDay(address user) external view returns (uint256) {
        return lastCheckInDay[user];
    }
    
    /**
     * @notice Query if user has checked in today
     * @param user User address
     * @return Whether checked in today
     */
    function hasCheckedInToday(address user) external view returns (bool) {
        return lastCheckInDay[user] == TimeUtils.currentUtcDay();
    }
    
    /**
     * @notice Query user's total check-in count
     * @param user User address
     * @return Total number of check-ins
     */
    function getTotalCheckIns(address user) external view returns (uint256) {
        return totalCheckIns[user];
    }
    
    /**
     * @notice Query user's consecutive check-in days
     * @param user User address
     * @return Consecutive days (0 if never checked in or broke streak)
     */
    function getConsecutiveDays(address user) external view returns (uint256) {
        return consecutiveDays[user];
    }
    
    /**
     * @notice Query user's complete check-in statistics
     * @param user User address
     * @return lastDay Last check-in UTC day
     * @return total Total check-ins count
     * @return consecutive Consecutive days
     * @return checkedInToday Whether checked in today
     */
    function getCheckInStats(address user) 
        external 
        view 
        returns (
            uint256 lastDay,
            uint256 total,
            uint256 consecutive,
            bool checkedInToday
        ) 
    {
        lastDay = lastCheckInDay[user];
        total = totalCheckIns[user];
        consecutive = consecutiveDays[user];
        checkedInToday = (lastDay == TimeUtils.currentUtcDay());
    }
    
    /**
     * @notice Batch query if multiple users checked in today
     * @param users Array of user addresses
     * @return Array of boolean values indicating check-in status
     */
    function batchHasCheckedInToday(address[] calldata users) 
        external 
        view 
        returns (bool[] memory) 
    {
        uint256 currentDay = TimeUtils.currentUtcDay();
        bool[] memory results = new bool[](users.length);
        
        for (uint256 i = 0; i < users.length; i++) {
            results[i] = (lastCheckInDay[users[i]] == currentDay);
        }
        
        return results;
    }
    
    /**
     * @notice Batch query check-in statistics for multiple users
     * @param users Array of user addresses
     * @return lastDays Array of last check-in days
     * @return totals Array of total check-in counts
     * @return consecutives Array of consecutive days
     */
    function batchGetCheckInStats(address[] calldata users)
        external
        view
        returns (
            uint256[] memory lastDays,
            uint256[] memory totals,
            uint256[] memory consecutives
        )
    {
        lastDays = new uint256[](users.length);
        totals = new uint256[](users.length);
        consecutives = new uint256[](users.length);
        
        for (uint256 i = 0; i < users.length; i++) {
            lastDays[i] = lastCheckInDay[users[i]];
            totals[i] = totalCheckIns[users[i]];
            consecutives[i] = consecutiveDays[users[i]];
        }
    }
    
    /**
     * @notice Get current UTC day
     * @return Current UTC day number
     */
    function getCurrentDay() external view returns (uint256) {
        return TimeUtils.currentUtcDay();
    }
    
    /**
     * @notice Get contract version
     * @return Version string
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}

