# MCP-K6 Application Testing with k6 Controlled by MCP

## Project Documentation

### Title Page
**Acronym – Title:**  
MCP-K6 – Application testing with k6 controlled by MCP

**Authors:**  
Szymon Szarek, Hubert Tułacz, Piotr Śmiałek, Tomasz Furgała

**Year, Group:**  
2026, 2

---

## Contents

1. [Introduction](#1-introduction)  
2. [Theoretical Background / Technology Stack](#2-theoretical-background--technology-stack)  
3. [Case Study Concept Description](#3-case-study-concept-description)  
4. [Case Study High-Level Architecture](#4-case-study-high-level-architecture)  
5. [Case Study Detailed Architecture](#5-case-study-detailed-architecture)  
6. [Environment Configuration Description](#6-environment-configuration-description)  
7. [Installation Method](#7-installation-method)  
8. [Demo Deployment Steps](#8-demo-deployment-steps)  
9. [Demo Description](#9-demo-description)  
10. [Summary – Conclusions](#10-summary--conclusions)  
11. [References](#11-references)

---

## 1. Introduction

The goal of this project is to demonstrate an automated application performance testing workflow using **k6 load testing controlled through an MCP server and LLM interface**.  

The tested application is deployed in a **Kubernetes cluster**, while load testing scenarios are executed using k6. The results of application performance and system behavior are visualized using Grafana dashboards.

The project demonstrates how modern observability tools and AI-driven control interfaces can be integrated to manage application testing and performance analysis.

---
## 2. Theoretical Background / Technology Stack

This project combines several modern DevOps and observability tools used for application deployment, performance testing, and monitoring.

**k6** is an open-source load testing tool used to simulate user traffic and evaluate application performance under load. Test scenarios are defined using JavaScript and allow the simulation of multiple virtual users interacting with application endpoints. In this project, the load tests target a ready demo web service based on the **QuickPizza** application.

**Kubernetes** is used as a container orchestration platform responsible for deploying and managing the application within a cluster environment.

The project also incorporates the **Model Context Protocol (MCP)**, which enables interaction between Large Language Models (LLMs) and external tools. Through an MCP server, the LLM can trigger and control load testing scenarios executed by k6.

For monitoring and observability, the project uses **Prometheus** and **Grafana**. Prometheus collects time-series metrics from the application and infrastructure, while Grafana provides dashboards for visualizing system behavior during load tests.

Together, these technologies form a pipeline for automated performance testing and observability of the deployed application.

---
## 3. Case Study Concept Description

This proof-of-concept evaluates the efficacy of LLM-driven control over performance testing within a Kubernetes-native environment. By leveraging a representative microservices architecture (QuickPizza-style), we demonstrate a shift from the LLM acting as a passive advisor to an active operational controller.

The core of this system is an integrated pipeline that bridges the gap between natural language intent and infrastructure reality.

- **Natural-Language Intent:** The user defines goals in plain English.  
- **MCP-Mediated Execution:** The Model Context Protocol (MCP) exposes k6 as executable tools. The model dynamically sets VUs, duration, and stages.  
- **Induced Load:** k6 generates synthetic traffic against in-cluster URLs.  
- **Multi-Signal Observability:** Prometheus and Grafana provide time-series evidence, allowing the LLM to interpret results and iterate.  

This represents an integrated human-LLM-tool-system pipeline for operational performance assessment, focusing on:

- Reproducibility  
- Action traceability  
- Management of LLM/tooling limitations through formal guardrails  

The following strategies are implemented to evaluate system stability and limits:

| Test Type              | Description                          | Objective                                                   |
|----------------------|--------------------------------------|-------------------------------------------------------------|
| **Smoke Testing**     | Minimal load                         | Verify scripts work and the system is responsive            |
| **Average-Load**      | Expected daily traffic               | Assess standard performance baselines                       |
| **Stress Testing**    | High load beyond limits              | Identify bottlenecks and observe degradation                |
| **Spike Testing**     | Sudden, extreme surges               | Test stability and autoscaling responsiveness               |
| **Soak (Endurance)**  | Prolonged duration                  | Uncover long-term issues like memory leaks                  |
| **Breakpoint**        | Continuous load increase             | Find absolute physical limits until system crash            |

## 4. Case Study High-Level Architecture

<img width="600" height="900" alt="image" src="https://github.com/user-attachments/assets/effef496-1ad2-4c9a-8dbd-4bbd591095a9" />

## 5. Case Study Detailed Architecture

## 6. Environment Configuration Description

## 7. Installation Method

## 8. Demo Deployment Steps

## 9. Demo Description

## 10. Summary – Conclusions

## 11. References

- k6 Documentation  
https://grafana.com/docs/k6/latest/

- k6 MCP Server  
https://github.com/QAInsights/k6-mcp-server

- Grafana Documentation  
https://grafana.com/docs/

- Kubernetes Documentation  
https://kubernetes.io/docs/

- QuickPizza 
https://github.com/grafana/quickpizza
