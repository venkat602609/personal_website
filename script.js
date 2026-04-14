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

const investmentForm = document.querySelector("#investment-form");
const initialInvestmentInput = document.querySelector("#initialInvestment");
const monthlyContributionInput = document.querySelector("#monthlyContribution");
const investmentYearsInput = document.querySelector("#investmentYears");
const annualReturnInput = document.querySelector("#annualReturn");
const returnVarianceInput = document.querySelector("#returnVariance");
const compoundFrequencyInput = document.querySelector("#compoundFrequency");

const totalContributedOutput = document.querySelector("#totalContributed");
const baseEndingValueOutput = document.querySelector("#baseEndingValue");
const investmentGainOutput = document.querySelector("#investmentGain");
const annualizedReturnOutput = document.querySelector("#annualizedReturn");
const lowEndingValueOutput = document.querySelector("#lowEndingValue");
const highEndingValueOutput = document.querySelector("#highEndingValue");
const varianceBandOutput = document.querySelector("#varianceBand");
const chartCaptionOutput = document.querySelector("#chartCaption");
const growthChart = document.querySelector("#growthChart");
const investmentInputs = [
  initialInvestmentInput,
  monthlyContributionInput,
  investmentYearsInput,
  annualReturnInput,
  returnVarianceInput,
  compoundFrequencyInput,
];
const toolTabs = Array.from(document.querySelectorAll(".tool-tab"));
const toolPanels = Array.from(document.querySelectorAll(".tool-panel"));

let loanAmountManuallyEdited = false;

function clamp(value, min = 0) {
  return Number.isFinite(value) ? Math.max(value, min) : min;
}

function formatCurrency(value) {
  return currencyFormatter.format(Math.round(value || 0));
}

function formatPercent(value) {
  return `${Number(value || 0).toFixed(1)}%`;
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

function buildInvestmentSeries(principal, monthlyContribution, years, annualRate, compoundsPerYear) {
  const months = years * 12;
  const series = [];
  let balance = principal;

  series.push({ label: "Start", value: balance });

  for (let month = 1; month <= months; month += 1) {
    balance += monthlyContribution;

    if (month % Math.max(12 / compoundsPerYear, 1) === 0) {
      balance *= 1 + annualRate / 100 / compoundsPerYear;
    }

    if (month % 12 === 0 || month === months) {
      series.push({
        label: `Year ${Math.ceil(month / 12)}`,
        value: balance,
      });
    }
  }

  return series;
}

function createLinePath(points) {
  return points
    .map((point, index) => `${index === 0 ? "M" : "L"} ${point.x.toFixed(2)} ${point.y.toFixed(2)}`)
    .join(" ");
}

function createAreaPath(points, baselineY) {
  if (!points.length) {
    return "";
  }

  const line = createLinePath(points);
  const last = points[points.length - 1];
  const first = points[0];
  return `${line} L ${last.x.toFixed(2)} ${baselineY.toFixed(2)} L ${first.x.toFixed(2)} ${baselineY.toFixed(2)} Z`;
}

function renderGrowthChart(lowSeries, baseSeries, highSeries) {
  const width = 720;
  const height = 360;
  const padding = { top: 24, right: 24, bottom: 42, left: 62 };
  const allValues = [...lowSeries, ...baseSeries, ...highSeries].map((point) => point.value);
  const maxValue = Math.max(...allValues, 1);
  const minValue = 0;
  const usableWidth = width - padding.left - padding.right;
  const usableHeight = height - padding.top - padding.bottom;
  const steps = Math.max(baseSeries.length - 1, 1);

  const mapPoints = (series) =>
    series.map((point, index) => ({
      x: padding.left + (usableWidth * index) / steps,
      y:
        padding.top +
        usableHeight -
        ((point.value - minValue) / (maxValue - minValue || 1)) * usableHeight,
      value: point.value,
      label: point.label,
    }));

  const lowPoints = mapPoints(lowSeries);
  const basePoints = mapPoints(baseSeries);
  const highPoints = mapPoints(highSeries);

  const yTicks = 4;
  const xTickStep = Math.max(Math.floor((basePoints.length - 1) / 4), 1);
  const gridLines = [];
  const xLabels = [];
  const yLabels = [];

  for (let tick = 0; tick <= yTicks; tick += 1) {
    const value = minValue + ((maxValue - minValue) * tick) / yTicks;
    const y = padding.top + usableHeight - (usableHeight * tick) / yTicks;
    gridLines.push(
      `<line x1="${padding.left}" y1="${y}" x2="${width - padding.right}" y2="${y}" stroke="rgba(24,79,69,0.12)" stroke-width="1" />`
    );
    yLabels.push(
      `<text x="${padding.left - 10}" y="${y + 4}" text-anchor="end" font-size="12" fill="#5d6963">${formatCurrency(value)}</text>`
    );
  }

  basePoints.forEach((point, index) => {
    if (index % xTickStep === 0 || index === basePoints.length - 1) {
      xLabels.push(
        `<text x="${point.x}" y="${height - 14}" text-anchor="middle" font-size="12" fill="#5d6963">${point.label.replace("Year ", "Y")}</text>`
      );
    }
  });

  growthChart.innerHTML = `
    <rect x="0" y="0" width="${width}" height="${height}" rx="18" fill="rgba(255,255,255,0.35)"></rect>
    ${gridLines.join("")}
    <path d="${createAreaPath(highPoints, height - padding.bottom)}" fill="rgba(184,109,59,0.08)"></path>
    <path d="${createAreaPath(lowPoints, height - padding.bottom)}" fill="rgba(138,169,157,0.10)"></path>
    <path d="${createLinePath(lowPoints)}" fill="none" stroke="#8aa99d" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"></path>
    <path d="${createLinePath(basePoints)}" fill="none" stroke="#184f45" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"></path>
    <path d="${createLinePath(highPoints)}" fill="none" stroke="#b86d3b" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"></path>
    ${basePoints
      .map(
        (point) =>
          `<circle cx="${point.x}" cy="${point.y}" r="3.5" fill="#184f45"><title>${point.label}: ${formatCurrency(point.value)}</title></circle>`
      )
      .join("")}
    ${yLabels.join("")}
    ${xLabels.join("")}
  `;
}

function updateInvestmentOutputs() {
  const initialInvestment = clamp(Number(initialInvestmentInput.value));
  const monthlyContribution = clamp(Number(monthlyContributionInput.value));
  const years = clamp(Number(investmentYearsInput.value), 1);
  const annualReturn = clamp(Number(annualReturnInput.value));
  const variance = clamp(Number(returnVarianceInput.value));
  const compoundsPerYear = clamp(Number(compoundFrequencyInput.value), 1);
  const lowReturn = Math.max(annualReturn - variance, 0);
  const highReturn = annualReturn + variance;

  const lowSeries = buildInvestmentSeries(
    initialInvestment,
    monthlyContribution,
    years,
    lowReturn,
    compoundsPerYear
  );
  const baseSeries = buildInvestmentSeries(
    initialInvestment,
    monthlyContribution,
    years,
    annualReturn,
    compoundsPerYear
  );
  const highSeries = buildInvestmentSeries(
    initialInvestment,
    monthlyContribution,
    years,
    highReturn,
    compoundsPerYear
  );

  const totalContributed = initialInvestment + monthlyContribution * years * 12;
  const baseEndingValue = baseSeries[baseSeries.length - 1].value;
  const investmentGain = baseEndingValue - totalContributed;
  const lowEndingValue = lowSeries[lowSeries.length - 1].value;
  const highEndingValue = highSeries[highSeries.length - 1].value;

  totalContributedOutput.textContent = formatCurrency(totalContributed);
  baseEndingValueOutput.textContent = formatCurrency(baseEndingValue);
  investmentGainOutput.textContent = formatCurrency(investmentGain);
  annualizedReturnOutput.textContent = formatPercent(annualReturn);
  lowEndingValueOutput.textContent = formatCurrency(lowEndingValue);
  highEndingValueOutput.textContent = formatCurrency(highEndingValue);
  varianceBandOutput.textContent = `${formatPercent(lowReturn)} to ${formatPercent(highReturn)}`;
  chartCaptionOutput.textContent = `Comparing ${years} years of growth at ${formatPercent(lowReturn)}, ${formatPercent(annualReturn)}, and ${formatPercent(highReturn)} annual returns.`;

  renderGrowthChart(lowSeries, baseSeries, highSeries);
}

function activateToolTab(targetId) {
  toolTabs.forEach((tab) => {
    const isActive = tab.dataset.tabTarget === targetId;
    tab.classList.toggle("is-active", isActive);
    tab.setAttribute("aria-selected", String(isActive));
  });

  toolPanels.forEach((panel) => {
    const isActive = panel.id === targetId;
    panel.classList.toggle("is-active", isActive);
    panel.hidden = !isActive;
  });
}

function syncToolTabFromHash() {
  const targetId = window.location.hash.replace("#", "");
  const matchingPanel = toolPanels.find((panel) => panel.id === targetId);
  activateToolTab(matchingPanel ? targetId : "mortgage-tool");
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

investmentInputs.forEach((input) => {
  input.addEventListener("input", updateInvestmentOutputs);
  input.addEventListener("change", updateInvestmentOutputs);
});

investmentForm.addEventListener("submit", (event) => {
  event.preventDefault();
  updateInvestmentOutputs();
});

toolTabs.forEach((tab) => {
  tab.addEventListener("click", () => {
    activateToolTab(tab.dataset.tabTarget);
  });
});

window.addEventListener("hashchange", syncToolTabFromHash);

deriveLoanAmount();
updateOutputs();
updateInvestmentOutputs();
syncToolTabFromHash();
