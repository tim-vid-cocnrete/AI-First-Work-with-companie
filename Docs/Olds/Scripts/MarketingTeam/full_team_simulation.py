import os
import sys
from crewai import Agent, Task, Crew, Process

# Check for API Keys
if "OPENAI_API_KEY" not in os.environ:
    print("WARNING: OPENAI_API_KEY is not set in environment variables.")
    print("Please set it in your .env file or export it.")

def create_marketing_crew(topic: str):
    # --- 1. Define Agents (The Team) ---

    # 1. Head of Marketing (Strategist)
    head_of_marketing = Agent(
        role='Head of Marketing & Strategy',
        goal='Develop high-level marketing strategies and coordinate the team.',
        backstory="""You lead a team of AI agents. Your job is not to write copy, 
        but to define WHAT and WHY we are doing it. You analyze the user's request 
        (business goals, budget, product) and break it down into tasks for the Copywriter 
        and CRM team. You are professional, strategic, and result-oriented.""",
        verbose=True,
        allow_delegation=True
    )

    # 2. CRM Strategy Lead (Retention)
    crm_lead = Agent(
        role='CRM Strategy Lead',
        goal='Maximize Customer Lifetime Value (LTV) and reduce Churn.',
        backstory="""You focus on what happens AFTER the purchase. You care about Retention Rate, 
        Churn Rate, and LTV. You analyze customer segments and design journeys to turn 
        one-time buyers into loyal advocates. You follow the motto: 'Retention is the new Acquisition'.""",
        verbose=True,
        allow_delegation=False
    )

    # 3. Senior Copywriter (Acquisition Content)
    copywriter = Agent(
        role='Senior Marketing Copywriter',
        goal='Create compelling, cliche-free marketing copy for acquisition.',
        backstory="""You work with the Head of Marketing to turn strategies into emotions. 
        You hate phrases like 'unique solution' or 'high quality'. You write in the customer's world. 
        You always offer multiple angles (e.g., Emotional, Direct, Provocative).""",
        verbose=True,
        allow_delegation=False
    )

    # 4. CRM Marketer (Retention Content)
    crm_marketer = Agent(
        role='CRM Marketing Specialist',
        goal='Craft personalized emails and automation workflows.',
        backstory="""You are the hands of the CRM strategy. You write email chains, push notifications, 
        and set up triggers. You know that 'Dear Customer' is a failure. Your content must drive 
        opens and clicks without being spammy. Mobile-first mindset.""",
        verbose=True,
        allow_delegation=False
    )

    # 5. Marketing Critic (Reviewer)
    manager_critic = Agent(
        role='Marketing Critic & Analyst',
        goal='Critique plans and content to prevent budget waste.',
        backstory="""You are the 'Devil's Advocate'. You look for holes in strategies and 'fluff' in copy. 
        You ask 'Why would they buy this?' and 'Where is the proof?'. You ensure everything is 
        fact-checked and optimized for conversion.""",
        verbose=True,
        allow_delegation=False
    )

    # --- 2. Define Tasks (The Process) ---

    # Task 1: Strategy Definition
    strategy_task = Task(
        description=f"""
        The user wants to launch a marketing campaign for: '{topic}'.
        
        As Head of Marketing, define the High-Level Strategy:
        1. Identify the Target Audience and concrete Business Goals.
        2. Define the Key Message and Channels.
        3. Delegate specific directions to the Copywriter (for ads) and CRM Lead (for retention).
        """,
        expected_output="A structured Marketing Strategy document with clear directives.",
        agent=head_of_marketing
    )

    # Task 2: CRM Strategy
    crm_strategy_task = Task(
        description=f"""
        Based on the Head of Marketing's strategy for '{topic}', 
        design a Retention/CRM Strategy.
        1. How will we onboard new users?
        2. How will we prevent churn?
        3. Define specific segments to target.
        """,
        expected_output="A CRM Strategy outlining segments and retention mechanics.",
        agent=crm_lead,
        context=[strategy_task]
    )

    # Task 3: Ad Copy Creation
    copywriting_task = Task(
        description=f"""
        Create marketing materials for usage in Channels defined by the Head of Marketing for '{topic}'.
        1. Write 3 variations of Ad Copy (Headlines + Body).
        2. Explain the psychological trigger behind each variation.
        NO CLICHES allowed.
        """,
        expected_output="3 distinct variations of Ad Copy with rationale.",
        agent=copywriter,
        context=[strategy_task]
    )

    # Task 4: Email Chain Creation
    email_task = Task(
        description=f"""
        Create a sequence of emails/messages based on the CRM Strategy for '{topic}'.
        1. Write a 3-step Email Sequence (e.g., Welcome -> Value -> Offer).
        2. Ensure high personalization and clear CTAs.
        """,
        expected_output="A 3-step Email Sequence with subject lines and body text.",
        agent=crm_marketer,
        context=[crm_strategy_task]
    )

    # Task 5: Final Review
    review_task = Task(
        description=f"""
        Review ALL output (Strategy, CRM Plan, Ad Copy, Emails) for '{topic}'.
        1. Rate the overall quality (1-10).
        2. Identify weak points or risks.
        3. Suggest specific improvements.
        """,
        expected_output="A Critical Review Report with ratings and improvement suggestions.",
        agent=manager_critic,
        context=[strategy_task, crm_strategy_task, copywriting_task, email_task]
    )

    # --- 3. Assemble Crew ---
    marketing_crew = Crew(
        agents=[head_of_marketing, crm_lead, copywriter, crm_marketer, manager_critic],
        tasks=[strategy_task, crm_strategy_task, copywriting_task, email_task, review_task],
        process=Process.sequential,  # Workflow: Strategy -> CRM Strat -> Copy -> Email -> Review
        verbose=True
    )

    return marketing_crew

if __name__ == "__main__":
    print("## AI Marketing Team Simulation ##")
    print("----------------------------------")
    print("Team: Head of Marketing, CRM Lead, Copywriter, CRM Specialist, Critic")
    
    user_topic = input("\nEnter the product/campaign topic (e.g., 'Black Friday Sale for Java Course'): ")
    
    if not user_topic:
        user_topic = "General Brand Awareness"
    
    crew = create_marketing_crew(user_topic)
    result = crew.kickoff()
    
    print("\n\n########################")
    print("## Final Team Report  ##")
    print("########################\n")
    print(result)
