// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GPUSharingContract {
    struct Offer {
        address provider;
        uint256 computingPower;
        uint256 pricePerHour;
        uint256 availabilityEndTime;
        bool isActive;
    }

    mapping(bytes32 => Offer) public offers;
    mapping(address => uint256) public userCollateral;
    uint256 public totalCollateral;

    event OfferCreated(bytes32 offerId, address provider, uint256 computingPower, uint256 pricePerHour, uint256 availabilityEndTime);
    event OfferAccepted(bytes32 offerId, address consumer, uint256 payment);
    event TaskCompleted(bytes32 offerId);
    event PaymentCreated(bytes32 offerId, address consumer,address provider, uint256 totalPayment);

    modifier onlyProvider(bytes32 offerId) {
        require(offers[offerId].provider == msg.sender, "Only the provider can perform this action");
        _;
    }

    modifier offerIsActive(bytes32 offerId) {
        require(offers[offerId].isActive && block.timestamp <= offers[offerId].availabilityEndTime, "Offer is no longer active");
        _;
    }

    function createOffer(uint256 computingPower, uint256 pricePerHour, uint256 durationHours) external {
        require(computingPower > 0 && pricePerHour > 0 && durationHours > 0, "Invalid parameters");
        
        bytes32 offerId = keccak256(abi.encodePacked(msg.sender, computingPower, pricePerHour, block.timestamp));
        offers[offerId] = Offer({
            provider: msg.sender,
            computingPower: computingPower,
            pricePerHour: pricePerHour,
            availabilityEndTime: block.timestamp + durationHours * 1 hours,
            isActive: true
        });

        emit OfferCreated(offerId, msg.sender, computingPower, pricePerHour, offers[offerId].availabilityEndTime);
    }

    function acceptOffer(bytes32 offerId) external payable offerIsActive(offerId) {
        Offer storage offer = offers[offerId];
        require(msg.value >= offer.pricePerHour, "Insufficient payment");

        userCollateral[msg.sender] += msg.value;
        emit OfferAccepted(offerId, msg.sender, msg.value);
    }

    function completeTask(bytes32 offerId) external onlyProvider(offerId) {
        require(block.timestamp <= offers[offerId].availabilityEndTime, "Offer has expired");
        // Perform task completion verification logic here
        
        uint256 payment = createPayment(offerId); // Call the function for payment calculation
        userCollateral[offers[offerId].provider] += payment;
        offers[offerId].isActive = false;
        
        emit TaskCompleted(offerId);
    }

    function withdrawCollateral() external {
        uint256 amount = userCollateral[msg.sender];
        require(amount > 0, "No collateral to withdraw");

        userCollateral[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function getOfferDetails(bytes32 offerId) public view returns (
    address provider,
    uint256 computingPower,
    uint256 pricePerHour,
    uint256 availabilityEndTime,
    bool isActive
    ) {
    Offer storage offer = offers[offerId];
        return (
            offer.provider,
            offer.computingPower,
            offer.pricePerHour,
            offer.availabilityEndTime,
            offer.isActive
        );
    }


    // Additional function for calculating payment based on machine specifications
    function calculatePayment(
        uint256 gpuTokenPrice,
        uint256 gpuCores,
        uint256 vRAM,
        uint256 systemCores,
        uint256 systemMemory,
        uint256 availabilityEndTime
    ) internal view returns (uint256) {
        // Calculate the base payment based on pricing factors
        uint256 basePayment = (gpuCores * gpuTokenPrice) + (vRAM * gpuTokenPrice) + (systemCores * gpuTokenPrice) + (systemMemory * gpuTokenPrice);
        
        // Calculate the total payment based on base payment and duration
        uint256 currentTime = block.timestamp;
        uint256 elapsedTime = currentTime > availabilityEndTime ? availabilityEndTime : currentTime;
        uint256 hoursElapsed = (elapsedTime - currentTime) / 3600; // Convert seconds to hours
        uint256 totalPayment = basePayment * hoursElapsed;
        
        require(totalPayment > 0, "Payment is zero");
        return totalPayment;
    }

    function createPayment(bytes32 offerId) public returns (uint256) {
    (address provider, , , uint256 availabilityEndTime, ) = getOfferDetails(offerId);

    // Sample pricing factors (replace with actual values)
    uint256 gpuTokenPrice = 100; // Replace with the actual GPU Token price
    uint256 gpuCores = 8; // Replace with the actual GPU cores
    uint256 vRAM = 16; // Replace with the actual vRAM in GB
    uint256 systemCores = 4; // Replace with the actual system cores
    uint256 systemMemory = 8; // Replace with the actual system memory in GB
    
    uint256 totalPayment = calculatePayment(gpuTokenPrice, gpuCores, vRAM, systemCores, systemMemory, availabilityEndTime);
    
    // Verify user's collateral and deduct payment
    require(userCollateral[msg.sender] >= totalPayment, "Insufficient collateral");
    userCollateral[msg.sender] -= totalPayment;
    
    // Update the totalCollateral state variable
    totalCollateral += totalPayment;
    
    // Transfer payment to the provider (use send function to handle failure)
    (bool sent, ) = provider.call{value: totalPayment}("");
    require(sent, "Failed to send Ether");
    
    emit PaymentCreated(offerId, msg.sender, provider, totalPayment);
    return totalPayment; 
}


}

