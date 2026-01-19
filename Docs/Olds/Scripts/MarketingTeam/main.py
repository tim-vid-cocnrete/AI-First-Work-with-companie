import os
from crewai import Agent, Task, Crew, Process
from crewai_tools import SerperDevTool

# Warning: You need to set OPENAI_API_KEY and SERPER_API_KEY in your environment variables
# os.environ["OPENAI_API_KEY"] = "YOUR_KEY"
# os.environ["SERPER_API_KEY"] = "YOUR_KEY"

def run_marketing_team(topic="AI in Marketing"):
    # 1. Define Agents
    market_researcher = Agent(
        role='Senior Market Researcher',
        goal='Uncover cutting-edge trends and news in {topic}',
        backstory="""You are an expert at digging deep into the internet to find 
        the most relevant and recent information. You have a nose for news 
        and can distinguish signal from noise.""",
        verbose=True,
        allow_delegation=False,
        tools=[SerperDevTool()]
    )

    content_writer = Agent(
        role='Senior Content Writer',
        goal='Write engaging blog posts about {topic} based on research',
        backstory="""You are a skilled copywriter who can take dry attributes 
        and turn them into compelling narratives. You write for a tech-savvy audience.""",
        verbose=True,
        allow_delegation=True
    )

    # 2. Define Tasks
    research_task = Task(
        description="""Conduct a comprehensive research about {topic}. 
        Identify key trends, major players, and recent breakthroughs.
        Your final answer should be a detailed summary report.""",
        agent=market_researcher,
        expected_output="A detailed summary report of the latest trends in {topic}."
    )

    writing_task = Task(
        description="""Using the research report, write a blog post about {topic}.
        The post should be engaging, informative, and formatted in Markdown.
        Focus on how these trends affect the future of work.""",
        agent=content_writer,
        context=[research_task],
        expected_output="An engaging blog post in Markdown format."
    )

    # 3. Form the Crew
    crew = Crew(
        agents=[market_researcher, content_writer],
        tasks=[research_task, writing_task],
        verbose=2,
        process=Process.sequential
    )

    # 4. Kickoff
    result = crew.kickoff(inputs={'topic': topic})
    return result

if __name__ == "__main__":
    print("## Welcome to the Marketing Crew ##")
    print("-----------------------------------")
    topic = input("Enter a topic to research/write about: ")
    result = run_marketing_team(topic)
    print("\n\n########################")
    print("## Here is your Blog Post ##")
    print("########################\n")
    print(result)
