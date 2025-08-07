 Task 13 - Docker Swarm Cronjobs.

   What is This Task About?

In this task, we explore how to schedule and run *cron jobs* using *Docker Swarm*.

Normally, in Linux we use `cron` to schedule repetitive tasks like running a script every minute or every day. But in Docker Swarm, there is *no built-in cronjob feature* like there is in Kubernetes.

So how do we schedule something in Docker Swarm? In this task, I’ll explain how we can *combine Linux cron + Docker Swarm* to run jobs like a cronjob, along with a simple working example I tested on my local machine.

---

    What is Docker Swarm?

Docker Swarm is a tool that helps you run your containers in a **cluster** of machines (called nodes). It’s like a mini version of Kubernetes but simpler and built into Docker.

You can deploy services, scale them, and manage containers across multiple machines using Swarm.

---

Problem: Docker Swarm has no Cronjob Support

Unlike Kubernetes (which has `CronJob` resources), Docker Swarm does *not have a built-in way to run a container at a specific time* like every minute or every night at 2am.

So how do we fix this?

---

 Solution: Use Linux Cron to Schedule Docker Swarm Tasks

We can do the following:

1. *Write a script* that does what we want (e.g., logs the time).
2. *Wrap the script in a Docker image**.
3. *Use Linux cron* on the host machine to *run a Docker Swarm service* that runs our job.
4. Done! It behaves just like a cronjob, but in Swarm.

---

 Example: Simple Cronjob in Docker Swarm

We will:
- Log the current date/time to a file.
- Build a Docker image for it.
- Deploy it using Docker Swarm.
- Run it every minute using Linux cron.


