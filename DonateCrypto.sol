// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

struct Campaign {
    uint256 id;
    address author;
    string title;
    string description;
    string imageUrl;
    string videoUrl;
    uint256 balance;
    uint256 goal;
    uint256 supporters;
    bool active;
    uint256 createdAt;
}

contract DonateCrypto {
    uint256 public donateFee = 2; // taxa de 2%
    uint256 public nextId = 0;
    uint256 public feesBalance = 0;
    address public admin;

    mapping(uint256 => Campaign) public campaigns; // id => campanha
    mapping(address => uint256[]) public userCampaignIds; // endereço do usuário => ids das campanhas
    mapping(uint256 => mapping(address => uint256)) public donations;
    mapping(uint256 => address[]) public campaignDonors;

    // global flags
    bool public hasBeenHacked = false;
    bool public hasNewVersion = false;
    bool public canCreateCampaigns = true;
    bool public canReceiveDonations = true;

    constructor() {
        admin = msg.sender; // define o deployer do contrato como admin
    }

    function addCampaign(
        string calldata title,
        string calldata description,
        string calldata videoUrl,
        string calldata imageUrl,
        uint256 goal
    ) public {
        require(hasBeenHacked == false, "The contract has been hacked");
        require(canCreateCampaigns == true, "Cannot create campaigns at this time");

        // Limite de 5 campanhas ativas por usuário
        uint256 activeCount = 0;
        uint256[] memory ids = userCampaignIds[msg.sender];
        for (uint256 i = 0; i < ids.length; i++) {
            if (campaigns[ids[i]].active) {
                activeCount++;
            }
        }
        require(activeCount < 10, "You can only have 10 active campaigns at a time");

        nextId++;

        Campaign memory newCampaign = Campaign({
            author: msg.sender,
            title: title,
            description: description,
            videoUrl: videoUrl,
            imageUrl: imageUrl,
            balance: 0,
            supporters: 0,
            active: true,
            createdAt: block.timestamp,
            id: nextId,
            goal: goal
        });

        campaigns[nextId] = newCampaign;
        userCampaignIds[msg.sender].push(nextId);
    }

    function editCampaign(
        uint256 id,
        string calldata title,
        string calldata description,
        string calldata videoUrl,
        string calldata imageUrl
    ) public {
        Campaign storage campaign = campaigns[id];
        require(campaign.author == msg.sender, "You do not have permission");
        require(campaign.active == true, "The campaign is closed");

        campaign.title = title;
        campaign.description = description;
        campaign.videoUrl = videoUrl;
        campaign.imageUrl = imageUrl;
    }

    /* function getRecentCampaigns() public view returns (Campaign[] memory) {
        uint256 count = nextId < 6 ? nextId : 6; // Verifica se há menos de 6 campanhas
        Campaign[] memory recentCampaigns = new Campaign[](count);

        for (uint256 i = 0; i < count; i++) {
            recentCampaigns[i] = campaigns[nextId - i];
        }

        return recentCampaigns;
    } */

    function getRecentCampaigns(uint256 page) public view returns (Campaign[] memory, uint256) {
        uint256 pageSize = 6;
        uint256 total = nextId;

        if (total == 0 || page == 0) {
            return (new Campaign[](0), 0);
        }

        uint256 totalPages = (total + pageSize - 1) / pageSize;
        if (page > totalPages) {
            return (new Campaign[](0), totalPages);
        }

        uint256 startIdx = total - (page - 1) * pageSize;
        uint256 endIdx = startIdx >= pageSize ? startIdx - pageSize + 1 : 1;
        uint256 resultSize = startIdx - endIdx + 1;

        Campaign[] memory recentCampaigns = new Campaign[](resultSize);
        uint256 idx = 0;
        for (uint256 i = startIdx; i >= endIdx; i--) {
            recentCampaigns[idx] = campaigns[i];
            idx++;
            if (i == 1) break; // previne underflow
        }

        return (recentCampaigns, totalPages);
    }

    function donate(uint256 id) public payable {
        require(hasBeenHacked == false, "The contract has been hacked");
        require(canReceiveDonations == true, "Cannot receive donations at this time");

        require(msg.value > 0, "You must send a donation value > 0");
        require(campaigns[id].active == true, "Cannot donate to this campaign");

        uint256 fee = (msg.value * donateFee) / 100; // Calcula 2% de taxa

        campaigns[id].balance += msg.value;
        feesBalance += fee; // Adiciona a taxa ao feesBalance

        if (donations[id][msg.sender] == 0) {
            campaigns[id].supporters += 1;
            campaignDonors[id].push(msg.sender);
        }
        donations[id][msg.sender] += msg.value;
    }

    function withdraw(uint256 campaignId) public {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.author == msg.sender, "You do not have permission");
        require(campaign.active == true, "The campaign is closed");
        require(campaign.balance > 0, "This campaign does not have enough balance");

        uint256 fee = (campaign.balance * donateFee) / 100;
        uint256 amountToWithdraw = campaign.balance - fee;
        address payable recipient = payable(campaign.author);

        campaign.active = false;

        (bool success, ) = recipient.call{value: amountToWithdraw}("");
        if (!success) {
            revert("Failed to withdraw funds");
        }
    }

    function getUserCampaigns(uint256 page) public view returns (Campaign[] memory, uint256) {
        uint256 pageSize = 10;
        uint256[] memory campaignIds = userCampaignIds[msg.sender];
        uint256 total = campaignIds.length;

        if (page == 0 || total == 0 || (page - 1) * pageSize >= total) {
            return (new Campaign[](0), 0);
        }

        uint256 totalPages = (total + pageSize - 1) / pageSize; // arredonda para cima

        uint256 start = (page - 1) * pageSize;
        uint256 end = start + pageSize;
        if (end > total) {
            end = total;
        }
        uint256 resultSize = end - start;

        Campaign[] memory userCampaigns = new Campaign[](resultSize);
        for (uint256 i = 0; i < resultSize; i++) {
            // Inverte a ordem: pega do índice mais alto para o mais baixo
            uint256 idx = total - 1 - (start + i);
            userCampaigns[i] = campaigns[campaignIds[idx]];
        }

        return (userCampaigns, totalPages);
    }

    function getDonors(uint256 campaignId) public view returns (address[] memory) {
        return campaignDonors[campaignId];
    }

    // Admin functions
    function adminActivateHackedFlag() public {
        require(msg.sender == admin, "Only the admin can do this");
        require(!hasBeenHacked, "Already set");
        hasBeenHacked = true;
    }

    function adminSetHasNewVersion(bool value) public {
        require(msg.sender == admin, "Only the admin can do this");
        hasNewVersion = value;
    }

    function adminSetCanCreateCampaigns(bool value) public {
        require(msg.sender == admin, "Only the admin can do this");
        canCreateCampaigns = value;
    }

    function adminSetCanDonate(bool value) public {
        require(msg.sender == admin, "Only the admin can do this");
        canReceiveDonations = value;
    }

    function adminWithdrawFees() public {
        require(msg.sender == admin, "Only the admin can withdraw fees");
        require(feesBalance > 0, "No fees available to withdraw");

        uint256 amount = feesBalance;

        (bool success, ) = payable(admin).call{value: amount}("");
        require(success == true, "Failed to withdraw fees");
        feesBalance = 0;
    }
}
