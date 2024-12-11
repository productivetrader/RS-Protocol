// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RSDistributionTracker is AccessControl, Pausable {
    bytes32 public constant TRACKER_ROLE = keccak256("TRACKER_ROLE");

    enum Phase {
        FIRST_RETRO,      // Phase 1: First Retroactive Airdrop
        TEAM_OPTIONS,     // Phase 2: Team Options
        DUTCH_AUCTION,    // Phase 3: Dutch Auction
        SECOND_RETRO,     // Phase 4: Second Retroactive Airdrop
        ANNUAL_BONUS,     // Phase 5: Annual Bonus Program
        LP_INCENTIVES,    // Phase 6: LP Incentives
        TREASURY         // Phase 7: Treasury Operations
    }

    struct PhaseStatus {
        bool isActive;
        uint256 startTime;
        uint256 endTime;
        uint256 distributed;
        uint256 allocated;
        bool isCompleted;
    }

    struct AnnualMetrics {
        uint256 lpIncentivesUsed;
        uint256 bonusesDistributed;
        uint256 participantCount;
        uint256 year;
    }

    // Phase tracking
    mapping(Phase => PhaseStatus) public phaseStatus;
    mapping(Phase => mapping(address => uint256)) public phaseDistributions;
    
    // Annual tracking
    mapping(uint256 => AnnualMetrics) public annualMetrics;
    
    // Allocation constants
    uint256 public constant FIRST_RETRO_AMOUNT = 7_000_000 * 1e18;
    uint256 public constant TEAM_OPTIONS_AMOUNT = 1_000_000 * 1e18;
    uint256 public constant DUTCH_AUCTION_AMOUNT = 20_000_000 * 1e18;
    uint256 public constant SECOND_RETRO_AMOUNT = 7_000_000 * 1e18;
    uint256 public constant ANNUAL_BONUS_TOTAL = 21_000_000 * 1e18;
    uint256 public constant LP_INCENTIVES_TOTAL = 40_000_000 * 1e18;
    uint256 public constant TREASURY_AMOUNT = 4_000_000 * 1e18;

    event PhaseStarted(Phase phase, uint256 timestamp);
    event PhaseCompleted(Phase phase, uint256 timestamp, uint256 distributed);
    event DistributionRecorded(Phase phase, address recipient, uint256 amount);
    event AnnualMetricsUpdated(uint256 year, uint256 lpIncentives, uint256 bonuses);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TRACKER_ROLE, msg.sender);
        
        // Initialize phase allocations
        phaseStatus[Phase.FIRST_RETRO].allocated = FIRST_RETRO_AMOUNT;
        phaseStatus[Phase.TEAM_OPTIONS].allocated = TEAM_OPTIONS_AMOUNT;
        phaseStatus[Phase.DUTCH_AUCTION].allocated = DUTCH_AUCTION_AMOUNT;
        phaseStatus[Phase.SECOND_RETRO].allocated = SECOND_RETRO_AMOUNT;
        phaseStatus[Phase.ANNUAL_BONUS].allocated = ANNUAL_BONUS_TOTAL;
        phaseStatus[Phase.LP_INCENTIVES].allocated = LP_INCENTIVES_TOTAL;
        phaseStatus[Phase.TREASURY].allocated = TREASURY_AMOUNT;
    }

    function startPhase(Phase _phase) external onlyRole(TRACKER_ROLE) {
        require(!phaseStatus[_phase].isActive, "Phase already active");
        require(!phaseStatus[_phase].isCompleted, "Phase already completed");
        
        if (_phase != Phase.FIRST_RETRO) {
            Phase previousPhase = Phase(uint8(_phase) - 1);
            require(phaseStatus[previousPhase].isCompleted, "Previous phase not completed");
        }

        phaseStatus[_phase].isActive = true;
        phaseStatus[_phase].startTime = block.timestamp;
        
        emit PhaseStarted(_phase, block.timestamp);
    }

    function recordDistribution(
        Phase _phase,
        address _recipient,
        uint256 _amount
    ) external onlyRole(TRACKER_ROLE) {
        require(phaseStatus[_phase].isActive, "Phase not active");
        require(
            phaseStatus[_phase].distributed + _amount <= phaseStatus[_phase].allocated,
            "Exceeds phase allocation"
        );

        phaseStatus[_phase].distributed += _amount;
        phaseDistributions[_phase][_recipient] += _amount;

        emit DistributionRecorded(_phase, _recipient, _amount);
    }

    function completePhase(Phase _phase) external onlyRole(TRACKER_ROLE) {
        require(phaseStatus[_phase].isActive, "Phase not active");
        
        phaseStatus[_phase].isActive = false;
        phaseStatus[_phase].isCompleted = true;
        phaseStatus[_phase].endTime = block.timestamp;

        emit PhaseCompleted(
            _phase,
            block.timestamp,
            phaseStatus[_phase].distributed
        );
    }

    function updateAnnualMetrics(
        uint256 _year,
        uint256 _lpIncentives,
        uint256 _bonuses,
        uint256 _participants
    ) external onlyRole(TRACKER_ROLE) {
        require(_year < 7, "Exceeds program duration");
        
        annualMetrics[_year] = AnnualMetrics({
            lpIncentivesUsed: _lpIncentives,
            bonusesDistributed: _bonuses,
            participantCount: _participants,
            year: _year
        });

        emit AnnualMetricsUpdated(_year, _lpIncentives, _bonuses);
    }

    // View functions
    function getPhaseStatus(Phase _phase) external view returns (PhaseStatus memory) {
        return phaseStatus[_phase];
    }

    function getRecipientDistribution(
        Phase _phase,
        address _recipient
    ) external view returns (uint256) {
        return phaseDistributions[_phase][_recipient];
    }

    function getAnnualMetrics(
        uint256 _year
    ) external view returns (AnnualMetrics memory) {
        return annualMetrics[_year];
    }

    function getRemainingAllocation(Phase _phase) external view returns (uint256) {
        return phaseStatus[_phase].allocated - phaseStatus[_phase].distributed;
    }
} 