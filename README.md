# Model of the smallholder farmers water needs in Limpopo, South Africa

We outline a method to support decision-makers in forecasting outcomes in e-flow scenarios where precise data is unavailable. We introduce a robust decision-making model to include expert knowledge as well as empirical evidence in assessing e-flow management options. The model distinguishes between scenarios representing different water use conditions and e-flow implementations and supports an extension of the e-flow concept to include more human aspects, such as the lives and livelihoods of smallholder farmers. This nuanced approach allows decision-makers to assess the impact of e-flow scenarios on agriculture and livelihoods. The model uses probability distributions of input variables and generates a custom model function predicting e-flow management decision outcomes. At the core of the model is a Monte Carlo simulation, generating numerous plausible outcomes based on probability distributions for input variables. The model generates outputs, including Net Present Value, allowing decision analysis without precise numerical data. To facilitate the model-building process, we designed an input table for storing estimate values locally and capturing uncertainties with 90% confidence intervals. The model development process allows us to address decision-relevant uncertainties in e-flows, making it a valuable tool for complex decision-making processes. The study underlines the practical application of the model through a script allowing for time series generation, event simulation, and value discounting based on measured values. Overall, our model offers an accessible framework for decision-makers navigating scenarios where precise data is unavailable.

Model and scripts are here https://github.com/CWWhitney/eflows_model, view the main document here https://github.com/CWWhitney/eflows_model/blob/main/index.md

The whole project is run from the {index} file. 
