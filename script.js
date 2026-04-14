const currencyFormatter = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
  maximumFractionDigits: 0,
});

const monthFormatter = new Intl.DateTimeFormat("en-US", {
  month: "short",
  year: "numeric",
});

const form = document.querySelector("#mortgage-form");
const homePriceInput = document.querySelector("#homePrice");
const downPaymentInput = document.querySelector("#downPayment");
const loanAmountInput = document.querySelector("#loanAmount");
const interestRateInput = document.querySelector("#interestRate");
const loanTermInput = document.querySelector("#loanTerm");
const extraPaymentInput = document.querySelector("#extraPayment");
const propertyTaxInput = document.querySelector("#propertyTax");
const insuranceInput = document.querySelector("#insurance");
const hoaInput = document.querySelector("#hoa");
const startDateInput = document.querySelector("#startDate");

const monthlyPIOutput = document.querySelector("#monthlyPI");
const monthlyTotalOutput = document.querySelector("#monthlyTotal");
const totalInterestOutput = document.querySelector("#totalInterest");
const payoffDateOutput = document.querySelector("#payoffDate");
const downPaymentRatioOutput = document.querySelector("#downPaymentRatio");
const totalPaymentsOutput = document.querySelector("#totalPayments");
const monthsSavedOutput = document.querySelector("#monthsSaved");
const tableCaptionOutput = document.querySelector("#tableCaption");
const scheduleBody = document.querySelector("#scheduleBody");
const liveInputs = [
  homePriceInput,
  downPaymentInput,
  loanAmountInput,
  interestRateInput,
  loanTermInput,
  extraPaymentInput,
  propertyTaxInput,
  insuranceInput,
  hoaInput,
  startDateInput,
];

let loanAmountManuallyEdited = false;

function clamp(value, min = 0) {
  return Number.isFinite(value) ? Math.max(value, min) : min;
}

function formatCurrency(value) {
  return currencyFormatter.format(Math.round(value || 0));
}

function parseMonthInput(value) {
  if (!value) {
    return new Date();
  }

  const [year, month] = value.split("-").map(Number);
  return new Date(year, month - 1, 1);
}

function addMonths(date, monthsToAdd) {
  return new Date(date.getFullYear(), date.getMonth() + monthsToAdd, 1);
}

function deriveLoanAmount() {
  if (loanAmountManuallyEdited) {
    return;
  }

  const homePrice = clamp(Number(homePriceInput.value));
  const downPayment = clamp(Number(downPaymentInput.value));
  loanAmountInput.value = Math.max(homePrice - downPayment, 0);
}

function calculateMonthlyPayment(principal, monthlyRate, totalMonths) {
  if (principal <= 0 || totalMonths <= 0) {
    return 0;
  }

  if (monthlyRate === 0) {
    return principal / totalMonths;
  }

  const growth = (1 + monthlyRate) ** totalMonths;
  return principal * ((monthlyRate * growth) / (growth - 1));
}

function buildSchedule(inputs) {
  const {
    principal,
    annualRate,
    termYears,
    extraPayment,
    annualTax,
    annualInsurance,
    monthlyHoa,
    startDate,
  } = inputs;

  const totalMonths = termYears * 12;
  const monthlyRate = annualRate / 12 / 100;
  const basePayment = calculateMonthlyPayment(principal, monthlyRate, totalMonths);
  const monthlyEscrow = annualTax / 12 + annualInsurance / 12 + monthlyHoa;

  let balance = principal;
  let totalInterest = 0;
  let totalPaid = 0;
  let monthIndex = 0;
  const rows = [];

  while (balance > 0.01 && monthIndex < totalMonths + 600) {
    monthIndex += 1;
    const interest = monthlyRate === 0 ? 0 : balance * monthlyRate;
    const scheduledPrincipal = Math.min(basePayment - interest, balance);
    const remainingAfterScheduled = balance - scheduledPrincipal;
    const appliedExtra = Math.min(extraPayment, Math.max(remainingAfterScheduled, 0));
    const totalPrincipal = scheduledPrincipal + appliedExtra;
    const payment = interest + totalPrincipal;

    balance = Math.max(balance - totalPrincipal, 0);
    totalInterest += interest;
    totalPaid += payment + monthlyEscrow;

    rows.push({
      month: monthIndex,
      date: monthFormatter.format(addMonths(startDate, monthIndex - 1)),
      payment,
      principal: totalPrincipal,
      interest,
      extra: appliedExtra,
      balance,
    });

    if (payment <= 0) {
      break;
    }
  }

  const baselineMonths = totalMonths;
  const monthsSaved = Math.max(baselineMonths - rows.length, 0);

  return {
    rows,
    monthlyPI: basePayment,
    monthlyTotal: basePayment + monthlyEscrow + extraPayment,
    totalInterest,
    totalPaid,
    payoffDate: rows.length ? rows[rows.length - 1].date : "-",
    monthsSaved,
  };
}

function renderSchedule(rows) {
  scheduleBody.innerHTML = "";

  const fragment = document.createDocumentFragment();

  rows.forEach((row) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${row.month}</td>
      <td>${row.date}</td>
      <td>${formatCurrency(row.payment)}</td>
      <td>${formatCurrency(row.principal)}</td>
      <td>${formatCurrency(row.interest)}</td>
      <td>${formatCurrency(row.extra)}</td>
      <td>${formatCurrency(row.balance)}</td>
    `;
    fragment.appendChild(tr);
  });

  scheduleBody.appendChild(fragment);
}

function updateOutputs() {
  const homePrice = clamp(Number(homePriceInput.value));
  const downPayment = clamp(Number(downPaymentInput.value));
  const principal = clamp(Number(loanAmountInput.value));
  const annualRate = clamp(Number(interestRateInput.value));
  const termYears = clamp(Number(loanTermInput.value), 1);
  const extraPayment = clamp(Number(extraPaymentInput.value));
  const annualTax = clamp(Number(propertyTaxInput.value));
  const annualInsurance = clamp(Number(insuranceInput.value));
  const monthlyHoa = clamp(Number(hoaInput.value));
  const startDate = parseMonthInput(startDateInput.value);

  const schedule = buildSchedule({
    principal,
    annualRate,
    termYears,
    extraPayment,
    annualTax,
    annualInsurance,
    monthlyHoa,
    startDate,
  });

  monthlyPIOutput.textContent = formatCurrency(schedule.monthlyPI);
  monthlyTotalOutput.textContent = formatCurrency(schedule.monthlyTotal);
  totalInterestOutput.textContent = formatCurrency(schedule.totalInterest);
  payoffDateOutput.textContent = schedule.payoffDate;
  downPaymentRatioOutput.textContent =
    homePrice > 0 ? `${((downPayment / homePrice) * 100).toFixed(1)}%` : "0%";
  totalPaymentsOutput.textContent = formatCurrency(schedule.totalPaid);
  monthsSavedOutput.textContent = `${schedule.monthsSaved}`;
  tableCaptionOutput.textContent = `Showing ${schedule.rows.length} monthly entries.`;

  renderSchedule(schedule.rows);
}

homePriceInput.addEventListener("input", deriveLoanAmount);
downPaymentInput.addEventListener("input", deriveLoanAmount);
loanAmountInput.addEventListener("input", () => {
  loanAmountManuallyEdited = true;
});
liveInputs.forEach((input) => {
  input.addEventListener("input", updateOutputs);
  input.addEventListener("change", updateOutputs);
});

form.addEventListener("submit", (event) => {
  event.preventDefault();
  updateOutputs();
});

deriveLoanAmount();
updateOutputs();
