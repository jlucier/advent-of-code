with open('input.txt', 'r') as f:
    steps = list(map(lambda l: l.strip(), f.readlines()))

dependencies = dict()
all_tasks = set()
for s in steps:
    s = s.split()
    dependencies.setdefault(s[-3], list()).append(s[1])
    all_tasks.update([s[1], s[-3]])

no_deps = all_tasks.difference(dependencies.keys())
task_order = [sorted(no_deps)[0]]
complete_tasks = set(task_order)
no_deps.difference_update(complete_tasks)

while len(dependencies) > 0:
    next_tasks = list()
    for task, deps in dependencies.items():
        if all(d in complete_tasks for d in deps):
            next_tasks.append(task)

    if len(no_deps) > 0:
        next_tasks.extend(no_deps)

    next_task = sorted(next_tasks)[0]
    task_order.append(next_task)
    complete_tasks.add(next_task)
    if next_task in dependencies:
        del dependencies[next_task]
    no_deps.difference_update(task_order)

print(''.join(task_order))
