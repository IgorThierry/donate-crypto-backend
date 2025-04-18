// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

struct Campaign {
    address author;
    string title;
    string description;
    string videoUrl;
    string imageUrl;
    uint256 balance;
    uint256 supporters;
    bool active;
    uint256 createdAt;
    uint256 id;
}

contract DonateCrypto {
    uint256 public donateFee = 2; // taxa de 2%
    uint256 public nextId = 0;
    uint256 public feesBalance = 0;
    address public admin;

    mapping(uint256 => Campaign) public campaigns; // id => campanha
    mapping(address => uint256[]) public userCampaignIds; // endereço do usuário => ids das campanhas
    mapping(uint256 => mapping(address => uint256)) public donations;

    constructor() {
        admin = msg.sender; // define o deployer do contrato como admin
    }

    function addCampaign(
        string calldata title,
        string calldata description,
        string calldata videoUrl,
        string calldata imageUrl
    ) public {
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
            id: nextId
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

    function getRecentCampaigns() public view returns (Campaign[] memory) {
        uint256 count = nextId < 6 ? nextId : 6; // Verifica se há menos de 6 campanhas
        Campaign[] memory recentCampaigns = new Campaign[](count);

        for (uint256 i = 0; i < count; i++) {
            recentCampaigns[i] = campaigns[nextId - i];
        }

        return recentCampaigns;
    }

    function donate(uint256 id) public payable {
        require(msg.value > 0, "You must send a donation value > 0");
        require(campaigns[id].active == true, "Cannot donate to this campaign");

        uint256 fee = (msg.value * donateFee) / 100; // Calcula 2% de taxa

        campaigns[id].balance += msg.value;
        feesBalance += fee; // Adiciona a taxa ao feesBalance

        if (donations[id][msg.sender] == 0) {
            campaigns[id].supporters += 1;
        }
        donations[id][msg.sender] += msg.value;
    }

    function withdraw(uint256 campaignId) public {
        Campaign memory campaign = campaigns[campaignId];
        require(campaign.author == msg.sender, "You do not have permission");
        require(campaign.active == true, "The campaign is closed");
        require(campaign.balance > 0, "This campaign does not have enough balance");

        address payable recipient = payable(campaign.author);

        uint256 fee = (campaign.balance * donateFee) / 100;
        uint256 amountToWithdraw = campaign.balance - fee;

        (bool success, ) = recipient.call{value: amountToWithdraw}("");
        require(success == true, "Failed to withdraw");

        campaigns[campaignId].active = false;
    }

    function adminWithdrawFees() public {
        require(msg.sender == admin, "Only the admin can withdraw fees");
        require(feesBalance > 0, "No fees available to withdraw");

        uint256 amount = feesBalance;

        (bool success, ) = payable(admin).call{value: amount}("");
        require(success == true, "Failed to withdraw fees");
        feesBalance = 0;
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
}
