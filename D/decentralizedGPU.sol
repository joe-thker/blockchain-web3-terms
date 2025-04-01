// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DecentralizedGPU
/// @notice Enables decentralized GPU resource sharing and renting dynamically.
contract DecentralizedGPU is Ownable, ReentrancyGuard {

    struct GPU {
        uint256 gpuId;
        address owner;
        string gpuSpecs; // GPU model, RAM, performance details
        uint256 hourlyRateWei;
        bool available;
    }

    struct Rental {
        uint256 rentalId;
        uint256 gpuId;
        address renter;
        uint256 startTime;
        uint256 endTime;
        uint256 totalPaid;
        bool active;
    }

    uint256 private nextGpuId;
    uint256 private nextRentalId;

    mapping(uint256 => GPU) public gpus;
    mapping(uint256 => Rental) public rentals;
    mapping(address => uint256[]) public ownerGPUs;

    event GPURegistered(uint256 indexed gpuId, address indexed owner);
    event GPURented(uint256 indexed rentalId, uint256 indexed gpuId, address indexed renter);
    event RentalEnded(uint256 indexed rentalId, uint256 indexed gpuId, address indexed renter, uint256 amountPaid);

    constructor() Ownable(msg.sender) {}

    /// @notice Register GPU resources dynamically
    function registerGPU(string calldata gpuSpecs, uint256 hourlyRateWei) external nonReentrant {
        require(bytes(gpuSpecs).length > 0, "GPU specs required");
        require(hourlyRateWei > 0, "Hourly rate must be greater than 0");

        uint256 gpuId = nextGpuId++;
        gpus[gpuId] = GPU({
            gpuId: gpuId,
            owner: msg.sender,
            gpuSpecs: gpuSpecs,
            hourlyRateWei: hourlyRateWei,
            available: true
        });

        ownerGPUs[msg.sender].push(gpuId);

        emit GPURegistered(gpuId, msg.sender);
    }

    /// @notice Rent an available GPU dynamically
    function rentGPU(uint256 gpuId, uint256 hoursToRent) external payable nonReentrant {
        GPU storage gpu = gpus[gpuId];
        require(gpu.available, "GPU not available");
        require(hoursToRent > 0, "Rent duration required");

        uint256 totalCost = gpu.hourlyRateWei * hoursToRent;
        require(msg.value >= totalCost, "Insufficient payment");

        gpu.available = false;

        uint256 rentalId = nextRentalId++;
        rentals[rentalId] = Rental({
            rentalId: rentalId,
            gpuId: gpuId,
            renter: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + (hoursToRent * 1 hours),
            totalPaid: totalCost,
            active: true
        });

        // Transfer payment to GPU owner immediately
        (bool sent,) = payable(gpu.owner).call{value: totalCost}("");
        require(sent, "Payment failed");

        // Refund any excess payment
        if (msg.value > totalCost) {
            (bool refund,) = payable(msg.sender).call{value: msg.value - totalCost}("");
            require(refund, "Refund failed");
        }

        emit GPURented(rentalId, gpuId, msg.sender);
    }

    /// @notice End GPU rental and mark GPU as available again
    function endRental(uint256 rentalId) external nonReentrant {
        Rental storage rental = rentals[rentalId];
        GPU storage gpu = gpus[rental.gpuId];

        require(rental.active, "Rental already ended");
        require(block.timestamp >= rental.endTime || msg.sender == gpu.owner, "Rental ongoing or unauthorized");

        rental.active = false;
        gpu.available = true;

        emit RentalEnded(rentalId, rental.gpuId, rental.renter, rental.totalPaid);
    }

    /// @notice Fetch GPU details
    function getGPU(uint256 gpuId) external view returns (GPU memory) {
        return gpus[gpuId];
    }

    /// @notice Fetch Rental details
    function getRental(uint256 rentalId) external view returns (Rental memory) {
        return rentals[rentalId];
    }

    /// @notice Fetch GPUs registered by an owner
    function getGPUsByOwner(address gpuOwner) external view returns (uint256[] memory) {
        return ownerGPUs[gpuOwner];
    }
}
