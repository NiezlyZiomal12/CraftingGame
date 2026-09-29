local DayCycle = {}

DayCycle.stamps = { "Morning", "Afternoon", "Evening", "Night" }
DayCycle.weekdays = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" }

function DayCycle.new()
    return { week = 1, day = 1, stamp = 1 }
end

function DayCycle.advance(calendar)
    if calendar.stamp < #DayCycle.stamps then
        calendar.stamp = calendar.stamp + 1
        return
    end

    calendar.stamp = 1
    if calendar.day < #DayCycle.weekdays then
        calendar.day = calendar.day + 1
    else
        calendar.day = 1
        calendar.week = calendar.week + 1
    end
end

return DayCycle
