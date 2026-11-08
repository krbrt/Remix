
// ======================================
// REWARD POINTS SYSTEM
// Frontend Preview - Demo Mode
// ======================================

// Demo data for the frontend preview.
// These values are NOT blockchain transactions.

let pointsBalance = 0;
let totalEarned = 0;
let membershipTier = "Bronze";

const transactions = [];

// HTML elements
const balanceElement = document.getElementById("pointsBalance");
const earnedElement = document.getElementById("totalEarned");
const tierElement = document.getElementById("membershipTier");
const availableElement = document.getElementById("availablePoints");
const transactionList = document.getElementById("transactionList");

// Display dashboard information
function updateDashboard() {
    balanceElement.textContent = pointsBalance.toLocaleString();
    earnedElement.textContent = totalEarned.toLocaleString();
    tierElement.textContent = membershipTier;
    availableElement.textContent = pointsBalance.toLocaleString();
}

// Display transactions
function updateTransactions() {
    if (transactions.length === 0) {
        transactionList.innerHTML = `
            <tr>
                <td colspan="5" class="empty-state">
                    No transactions yet.
                </td>
            </tr>
        `;
        return;
    }

    transactionList.innerHTML = transactions.map(transaction => `
        <tr>
            <td>${transaction.name}</td>
            <td>${transaction.type}</td>
            <td>${transaction.points.toLocaleString()}</td>
            <td>${transaction.date}</td>
            <td>${transaction.status}</td>
        </tr>
    `).join("");
}

// Add demo transaction
function addTransaction(name, type, points) {
    transactions.unshift({
        name: name,
        type: type,
        points: points,
        date: new Date().toLocaleString(),
        status: "Demo"
    });

    updateTransactions();
}

// DEMO: EARN POINTS
document.getElementById("earnForm").addEventListener("submit", function(event) {
    event.preventDefault();

    const address = document.getElementById("earnAddress").value.trim();
    const amount = Number(document.getElementById("earnAmount").value);

    if (!/^0x[a-fA-F0-9]{40}$/.test(address)) {
        alert("Please enter a valid Ethereum wallet address.");
        return;
    }

    if (!Number.isSafeInteger(amount) || amount <= 0) {
        alert("Please enter a valid positive whole number of points.");
        return;
    }

    pointsBalance += amount;
    totalEarned += amount;

    addTransaction("Points Earned", "Earn", amount);
    updateDashboard();

    alert("Demo: Points added to the frontend preview!");

    this.reset();
});

// DEMO: REDEEM POINTS
document.getElementById("redeemForm").addEventListener("submit", function(event) {
    event.preventDefault();

    const amount = Number(document.getElementById("redeemAmount").value);

    if (!Number.isSafeInteger(amount) || amount <= 0) {
        alert("Please enter a valid positive whole number of points.");
        return;
    }

    if (amount > pointsBalance) {
        alert("Insufficient points balance!");
        return;
    }

    pointsBalance -= amount;

    addTransaction("Points Redeemed", "Redeem", -amount);
    updateDashboard();

    alert("Demo: Points redeemed in the frontend preview!");

    this.reset();
});

// DEMO: CONNECT WALLET BUTTON
document.getElementById("connectWallet").addEventListener("click", function() {
    alert(
        "Wallet connection will be implemented in the blockchain integration step."
    );
});

// NAVIGATION ACTIVE STATE
document.querySelectorAll(".nav-link").forEach(link => {
    link.addEventListener("click", function() {
        document.querySelectorAll(".nav-link").forEach(item => {
            item.classList.remove("active");
        });

        this.classList.add("active");
    });
});

// Initial dashboard display
updateDashboard();
updateTransactions();
