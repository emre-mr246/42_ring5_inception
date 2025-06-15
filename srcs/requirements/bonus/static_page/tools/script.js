const testBtn = document.getElementById('testBtn');
const runawayBtn = document.getElementById('runawayBtn');
const messageElement = document.getElementById('testMessage');
let keySequence = [];

function setInitialRunawayPosition() {
	const viewportWidth = window.innerWidth;
	const viewportHeight = window.innerHeight;
	runawayBtn.style.top = (viewportHeight / 2 - runawayBtn.offsetHeight / 2) + 'px';
	runawayBtn.style.left = (viewportWidth / 2 - runawayBtn.offsetWidth / 2) + 'px';
}

testBtn.addEventListener('click', () => {
	testBtn.style.display = 'none';
	runawayBtn.style.display = 'block';
	setInitialRunawayPosition();
	messageElement.style.display = 'none';
	console.log("'Start Test' button clicked, runaway button is shown.");
});

runawayBtn.addEventListener('mouseover', () => {
	const viewportWidth = window.innerWidth;
	const viewportHeight = window.innerHeight;
	const btnRect = runawayBtn.getBoundingClientRect();
	const margin = 20;

	let newTop = Math.random() * (viewportHeight - btnRect.height - 2 * margin) + margin;
	let newLeft = Math.random() * (viewportWidth - btnRect.width - 2 * margin) + margin;

	runawayBtn.style.top = newTop + 'px';
	runawayBtn.style.left = newLeft + 'px';
});

runawayBtn.addEventListener('click', () => {
	console.log("Runaway button clicked, but this is a fake button!");
});

document.addEventListener('keydown', (event) => {
	const keyPressed = event.key;

	if (keyPressed === '4') {
		keySequence = ['4'];
	} else if (keyPressed === '2' && keySequence.length === 1 && keySequence[0] === '4') {
		keySequence.push('2');
		if (keySequence.join('') === '42') {
			showSuccessMessageAndConfetti();
			keySequence = [];
		}
	} else {
		keySequence = [];
	}
});

function showSuccessMessageAndConfetti() {
	testBtn.style.display = 'none';
	runawayBtn.style.display = 'none';
	messageElement.innerHTML = "🎉 Congratulations! 🎉<br>You have successfully passed the Staffoğulları family entrance test!<br>Welcome to the family!";
	messageElement.style.color = '#28a745';
	messageElement.style.fontWeight = 'bold';
	messageElement.style.display = 'block';
	const congratsImg = document.getElementById('congratsImg');
	congratsImg.style.display = 'block';
	createConfetti();
}

window.addEventListener('resize', () => {
	if (runawayBtn.style.display === 'block') {
		setInitialRunawayPosition();
	}
});

function createConfetti() {
	const confettiContainer = document.body;
	const colors = ['#ff0', '#f00', '#0f0', '#00f', '#f0f', '#0ff', '#ff9900', '#cc33ff'];
	for (let i = 0; i < 150; i++) {
		const confetti = document.createElement('div');
		confetti.style.position = 'absolute';
		const size = Math.random() * 12 + 6;
		confetti.style.width = size + 'px';
		confetti.style.height = size + 'px';
		confetti.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
		confetti.style.opacity = Math.random() * 0.6 + 0.4;
		confetti.style.borderRadius = '50%';

		const messageRect = messageElement.getBoundingClientRect();
		const startX = messageRect.left + messageRect.width / 2 + (Math.random() - 0.5) * messageRect.width;
		const startY = messageRect.top + (Math.random() - 0.5) * 50;

		confetti.style.left = startX + 'px';
		confetti.style.top = startY + 'px';
		
		confettiContainer.appendChild(confetti);

		const angle = Math.random() * Math.PI * 2;
		const velocity = Math.random() * 150 + 100;
		const gravity = 0.3;
		let vx = Math.cos(angle) * velocity / 25;
		let vy = Math.sin(angle) * velocity / 25 - (Math.random() * 5 + 2);
		const rotation = Math.random() * 720 - 360;
		const duration = Math.random() * 3000 + 2000;

		let startTime = null;
		function animateConfetti(timestamp) {
			if (!startTime) startTime = timestamp;
			const progress = timestamp - startTime;

			vy += gravity * (progress / 1000);
			
			const currentX = parseFloat(confetti.style.left) + vx;
			const currentY = parseFloat(confetti.style.top) + vy;
			const currentRotation = (progress / duration) * rotation;

			confetti.style.left = currentX + 'px';
			confetti.style.top = currentY + 'px';
			confetti.style.transform = `rotate(${currentRotation}deg)`;
			confetti.style.opacity = Math.max(0, 1 - (progress / duration) * 1.5);

			if (progress < duration && parseFloat(confetti.style.opacity) > 0) {
				requestAnimationFrame(animateConfetti);
			} else {
				confetti.remove();
			}
		}
		requestAnimationFrame(animateConfetti);
	}
}
